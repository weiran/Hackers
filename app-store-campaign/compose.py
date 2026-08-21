#!/usr/bin/env python3
"""Compose the Hackers App Store campaign from real captures and generated backgrounds."""

from __future__ import annotations

import json
import math
import shutil
import zipfile
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parent
CONFIG = json.loads((ROOT / "campaign.json").read_text())
OUTPUT_ROOT = ROOT / "output"
UPLOAD_ROOT = OUTPUT_ROOT / "upload"
REVIEW_ROOT = ROOT / "review"
ICON_PATH = ROOT / "assets/brand/app-icon.png"
ACCEPTED_SIZES = {
    (1242, 2688),
    (1284, 2778),
    (1320, 2868),
    (2064, 2752),
}


def path_for(value: str | Path) -> Path:
    path = Path(value)
    return path if path.is_absolute() else ROOT / path


def font(size: int) -> ImageFont.FreeTypeFont:
    try:
        return ImageFont.truetype(CONFIG["font"], size=size)
    except OSError:
        return ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", size=size)


def cover(image: Image.Image, size: tuple[int, int], centering: tuple[float, float]) -> Image.Image:
    return ImageOps.fit(
        image.convert("RGB"),
        size,
        method=Image.Resampling.LANCZOS,
        centering=centering,
    ).convert("RGBA")


def gradient_overlay(size: tuple[int, int], top_alpha: int, bottom_alpha: int) -> Image.Image:
    width, height = size
    ramp = Image.new("L", (1, height))
    pixels = ramp.load()
    for y in range(height):
        progress = min(1.0, y / max(1, int(height * 0.43)))
        pixels[0, y] = int(top_alpha + (bottom_alpha - top_alpha) * progress)
    alpha = ramp.resize((width, height), Image.Resampling.BILINEAR)
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    overlay.putalpha(alpha)
    return overlay


def glow(size: tuple[int, int], center: tuple[float, float], color: tuple[int, int, int], radius: int, alpha: int) -> Image.Image:
    width, height = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    cx, cy = int(width * center[0]), int(height * center[1])
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=(*color, alpha))
    return layer.filter(ImageFilter.GaussianBlur(radius=max(1, radius // 2)))


def inner_screen_mask(frame: Image.Image, spec: dict) -> Image.Image:
    x, y, width, height = spec["screen"]
    frame_alpha = frame.getchannel("A")
    transparent = ImageChops.invert(frame_alpha.crop((x, y, x + width, y + height)))
    rounded = Image.new("L", (width, height), 0)
    ImageDraw.Draw(rounded).rounded_rectangle(
        (0, 0, width - 1, height - 1),
        radius=spec["radius"],
        fill=255,
    )
    return ImageChops.multiply(transparent, rounded)


def compose_device(screen_path: Path, kind: str, height: int, rotation: float) -> Image.Image:
    frame_spec = CONFIG["frames"][kind]
    frame = Image.open(path_for(frame_spec["path"])).convert("RGBA")
    screen_x, screen_y, screen_width, screen_height = frame_spec["screen"]
    screen = Image.open(screen_path).convert("RGB")
    fitted_screen = ImageOps.fit(
        screen,
        (screen_width, screen_height),
        method=Image.Resampling.LANCZOS,
        centering=(0.5, 0.5),
    )

    underlay = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    underlay.paste(
        fitted_screen,
        (screen_x, screen_y),
        inner_screen_mask(frame, frame_spec),
    )
    device = Image.alpha_composite(underlay, frame)
    scale = height / device.height
    scaled = device.resize((round(device.width * scale), height), Image.Resampling.LANCZOS)

    shadow_alpha = scaled.getchannel("A").filter(ImageFilter.GaussianBlur(max(16, round(height * 0.025))))
    shadow_alpha = shadow_alpha.point(lambda value: round(value * 0.34))
    shadow = Image.new("RGBA", scaled.size, (0, 0, 0, 0))
    shadow.putalpha(shadow_alpha)
    pad = max(40, round(height * 0.045))
    combined = Image.new("RGBA", (scaled.width + pad * 2, scaled.height + pad * 2), (0, 0, 0, 0))
    combined.alpha_composite(shadow, (pad + round(height * 0.012), pad + round(height * 0.018)))
    combined.alpha_composite(scaled, (pad, pad))
    return combined.rotate(rotation, resample=Image.Resampling.BICUBIC, expand=True)


def draw_lockup(canvas: Image.Image, slide_number: int, align: str, margin: int) -> None:
    draw = ImageDraw.Draw(canvas)
    pill_width = round(canvas.width * 0.28)
    pill_height = round(canvas.width * 0.055)
    x = margin
    y = round(canvas.height * 0.035)
    pill = Image.new("RGBA", (pill_width, pill_height), (0, 0, 0, 0))
    pill_draw = ImageDraw.Draw(pill)
    pill_draw.rounded_rectangle(
        (0, 0, pill_width - 1, pill_height - 1),
        radius=round(pill_height / 2),
        fill=(14, 12, 22, 184),
        outline=(255, 255, 255, 34),
        width=max(1, round(canvas.width * 0.001)),
    )
    icon_size = round(pill_height * 0.72)
    icon = Image.open(ICON_PATH).convert("RGBA").resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    pill.alpha_composite(icon, (round(pill_height * 0.16), round((pill_height - icon_size) / 2)))
    label_font = font(round(canvas.width * 0.018))
    pill_draw.text(
        (round(pill_height * 1.06), pill_height / 2),
        "HACKERS  /  HN READER",
        font=label_font,
        fill=(248, 245, 240, 232),
        anchor="lm",
    )
    canvas.alpha_composite(pill, (x, y))

    number_font = font(round(canvas.width * 0.017))
    number = f"{slide_number:02d}  /  06"
    number_bbox = draw.textbbox((0, 0), number, font=number_font)
    number_x = canvas.width - margin - (number_bbox[2] - number_bbox[0])
    draw.text((number_x, y + pill_height / 2), number, font=number_font, fill=(248, 245, 240, 176), anchor="lm")


def draw_copy(canvas: Image.Image, slide: dict, slide_number: int, kind: str) -> None:
    draw = ImageDraw.Draw(canvas)
    margin = round(canvas.width * (0.085 if kind == "iphone" else 0.075))
    draw_lockup(canvas, slide_number, slide["text_align"], margin)
    title_size = round(canvas.width * (0.078 if kind == "iphone" else 0.066))
    subtitle_size = round(canvas.width * (0.026 if kind == "iphone" else 0.022))
    title_font = font(title_size)
    subtitle_font = font(subtitle_size)
    title_top = round(canvas.height * slide["text_top"])
    title_box = (margin, title_top, canvas.width - margin, title_top + round(canvas.height * 0.19))
    title_width = title_box[2] - title_box[0]
    title_bbox = draw.multiline_textbbox((0, 0), slide["title"], font=title_font, spacing=round(title_size * 0.08))
    title_height = title_bbox[3] - title_bbox[1]
    if slide["text_align"] == "center":
        title_x = canvas.width / 2
        anchor = "ma"
    else:
        title_x = margin
        anchor = "la"
    draw.multiline_text(
        (title_x, title_top),
        slide["title"],
        font=title_font,
        fill=(248, 245, 240, 255),
        spacing=round(title_size * 0.08),
        align=slide["text_align"],
        anchor=anchor,
    )
    subtitle_y = title_top + title_height + round(canvas.height * 0.018)
    if slide["text_align"] == "center":
        subtitle_anchor = "ma"
        subtitle_x = canvas.width / 2
    else:
        subtitle_anchor = "la"
        subtitle_x = margin
    draw.text(
        (subtitle_x, subtitle_y),
        slide["subtitle"],
        font=subtitle_font,
        fill=(207, 201, 214, 238),
        anchor=subtitle_anchor,
    )
    rule_y = subtitle_y + round(subtitle_size * 1.55)
    rule_width = round(canvas.width * 0.16)
    if slide["text_align"] == "center":
        rule_x = round((canvas.width - rule_width) / 2)
    else:
        rule_x = margin
    draw.line((rule_x, rule_y, rule_x + rule_width, rule_y), fill=(160, 111, 237, 225), width=max(2, round(canvas.width * 0.002)))
    draw.ellipse(
        (rule_x + rule_width - round(canvas.width * 0.012), rule_y - round(canvas.width * 0.006), rule_x + rule_width + round(canvas.width * 0.004), rule_y + round(canvas.width * 0.01)),
        fill=(255, 147, 0, 238),
    )


def compose_slide(slide: dict, output: dict, slide_number: int) -> Image.Image:
    width, height = output["size"]
    kind = output["kind"]
    background = cover(Image.open(path_for(slide["background"])), (width, height), (0.5, 0.47 if kind == "iphone" else 0.52))
    canvas = background
    canvas = Image.alpha_composite(canvas, gradient_overlay((width, height), 128, 4))
    canvas = Image.alpha_composite(canvas, glow((width, height), (0.18, 0.78), (160, 111, 237), round(width * 0.28), 52))
    canvas = Image.alpha_composite(canvas, glow((width, height), (0.88, 0.46), (255, 147, 0), round(width * 0.24), 28))

    layout = slide["device"][kind]
    screen_dir = ROOT / "assets/screens" / ("iphone-dark" if kind == "iphone" else "ipad-dark")
    screen_path = screen_dir / slide["screen"]
    device = compose_device(screen_path, kind, round(height * layout["height"]), layout["rotation"])
    device_x = round(width * layout["center"][0] - device.width / 2)
    device_y = round(height * layout["center"][1] - device.height / 2)
    canvas.alpha_composite(device, (device_x, device_y))
    draw_copy(canvas, slide, slide_number, kind)
    return canvas.convert("RGB")


def output_name(slide: dict, output: dict) -> str:
    width, height = output["size"]
    return f"{slide['id']}-{width}x{height}.png"


def make_contact_sheet(paths: Iterable[Path]) -> None:
    paths = list(paths)
    columns = 4
    thumb_width = 300
    gap = 24
    label_height = 44
    thumbnails: list[tuple[Path, Image.Image]] = []
    for path in paths:
        image = Image.open(path).convert("RGB")
        ratio = thumb_width / image.width
        thumbnails.append((path, image.resize((thumb_width, round(image.height * ratio)), Image.Resampling.LANCZOS)))
    row_heights = []
    for start in range(0, len(thumbnails), columns):
        row_heights.append(max(image.height + label_height for _, image in thumbnails[start:start + columns]))
    sheet_width = columns * thumb_width + (columns + 1) * gap
    sheet_height = sum(row_heights) + (len(row_heights) + 1) * gap
    sheet = Image.new("RGB", (sheet_width, sheet_height), (11, 10, 16))
    draw = ImageDraw.Draw(sheet)
    label_font = font(20)
    y = gap
    for row, row_height in enumerate(row_heights):
        for column in range(columns):
            index = row * columns + column
            if index >= len(thumbnails):
                break
            path, image = thumbnails[index]
            x = gap + column * (thumb_width + gap)
            sheet.paste(image, (x, y))
            draw.text((x, y + image.height + 9), path.name, font=label_font, fill=(238, 234, 244))
        y += row_height + gap
    REVIEW_ROOT.mkdir(parents=True, exist_ok=True)
    sheet.save(REVIEW_ROOT / "contact-sheet.png", format="PNG", optimize=True)


def validate(paths: Iterable[Path]) -> None:
    paths = list(paths)
    if not paths:
        raise RuntimeError("No campaign PNGs were generated")
    for path in paths:
        with Image.open(path) as image:
            if image.size not in ACCEPTED_SIZES:
                raise RuntimeError(f"Invalid dimensions for {path}: {image.size}")
            if image.mode != "RGB":
                raise RuntimeError(f"Expected RGB upload PNG: {path} ({image.mode})")
    if len({path.name for path in paths}) != len(paths):
        raise RuntimeError("Duplicate output names")


def build() -> None:
    shutil.rmtree(OUTPUT_ROOT, ignore_errors=True)
    shutil.rmtree(REVIEW_ROOT, ignore_errors=True)
    OUTPUT_ROOT.mkdir(parents=True, exist_ok=True)
    UPLOAD_ROOT.mkdir(parents=True, exist_ok=True)
    generated: list[Path] = []
    for output in CONFIG["outputs"]:
        device_dir = OUTPUT_ROOT / output["kind"] / output["id"]
        device_dir.mkdir(parents=True, exist_ok=True)
        for slide_number, slide in enumerate(CONFIG["slides"], start=1):
            image = compose_slide(slide, output, slide_number)
            name = output_name(slide, output)
            output_path = device_dir / name
            image.save(output_path, format="PNG", optimize=True)
            upload_name = f"{output['id']}-{name}"
            upload_path = UPLOAD_ROOT / upload_name
            image.save(upload_path, format="PNG", optimize=True)
            generated.append(upload_path)
    validate(generated)
    make_contact_sheet(generated)
    archive = ROOT / "app-store-screenshots.zip"
    if archive.exists():
        archive.unlink()
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        for path in sorted(generated):
            bundle.write(path, arcname=path.name)
    with zipfile.ZipFile(archive) as bundle:
        members = bundle.namelist()
        if len(members) != len(generated) or any(not member.endswith(".png") for member in members):
            raise RuntimeError("Archive contains unexpected files")
    print(f"Generated {len(generated)} upload PNGs")
    print(f"Contact sheet: {REVIEW_ROOT / 'contact-sheet.png'}")
    print(f"Archive: {archive}")


if __name__ == "__main__":
    build()
