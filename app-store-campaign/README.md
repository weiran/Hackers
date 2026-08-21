# Hackers App Store campaign

This campaign refreshes six marketing flows: focused feed reading, in-app
stories, contextual comments, search, synced read state, and deep threads.

## Art direction

The campaign is dark-led and quietly cinematic: ink, ultraviolet, ember, paper,
smoked acrylic, and editorial signal forms. Generated backgrounds contain no
phones, UI, text, logos, or watermarks. Every overlaid screen is a full-resolution
dark-mode capture from the real app target running against live public Hacker
News data on iOS 27 simulators, without `HACKERS_UI_TESTING` enabled.

The copy is rendered by `compose.py` with the system font after compositing, so
generated imagery never supplies readable marketing text.

## Build

```bash
python3 app-store-campaign/compose.py
```

The script clears and rebuilds `output/`, validates RGB PNG dimensions, creates
`review/contact-sheet.png`, and writes a flat `app-store-screenshots.zip` that
contains only final upload PNGs.

The upload set includes current Apple 6.9-inch iPhone output (`1320x2868`), the
two portrait sizes requested by the screenshot skill (`1284x2778` and
`1242x2688`), and the current 13-inch iPad portrait output (`2064x2752`).

The raw screen sources are captured at 1206x2622 from iPhone 17 Pro and
2064x2752 from iPad Pro 13-inch, then fitted into the device frames by the
compositor. The six live states cover the feed, story/comments, a scrolled
conversation, a `swift` search, read/dimmed state, and a deeper thread. Public
Hacker News content changes over time, so recapture the raw sources before a
future App Store submission if freshness matters.
