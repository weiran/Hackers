//
//  CommentRow.swift
//  Comments
//
//  Extracted from CommentsComponents to keep file size manageable.
//

import DesignSystem
import Domain
import SwiftUI
import UIKit

struct CommentRowState: Equatable, Identifiable {
    let id: Int
    let author: String
    let age: String
    let level: Int
    let visibility: CommentVisibilityType
    let isPostAuthor: Bool
    let isUpvoted: Bool
    let canVote: Bool
    let canUnvote: Bool
    let styledText: AttributedString?
}

struct CommentRow: View {
    private enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 16
        static let nestedTopPadding: CGFloat = 12
        static let railSpacing: CGFloat = 24
        static let railContentSpacing: CGFloat = 24
        static let maxVisibleGuides = 3
    }

    @Environment(\.displayScale) private var displayScale

    let state: CommentRowState
    let onToggle: () -> Void
    let onUpvote: () -> Void
    let onUnvote: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void

    var body: some View {
        rowDisplay
            .contentShape(.interaction, Rectangle())
            .onTapGesture(perform: onToggle)
            .overlay(alignment: .topLeading) {
                rowControls
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("comments.comment.\(state.id)")
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(state.visibility == .visible ? "Tap to collapse" : "Tap to expand")
            .accessibilityAction(.default, onToggle)
            .contextMenu {
                if state.canVote, !state.isUpvoted {
                    Button(action: onUpvote) {
                        Label("Upvote", systemImage: "arrow.up")
                    }
                }
                if state.canUnvote, state.isUpvoted {
                    Button(action: onUnvote) {
                        Label("Unvote", systemImage: "arrow.uturn.down")
                    }
                }
                Divider()
                Button(action: onCopy) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                Divider()
                Button(action: onShare) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
    }

    private var rowDisplay: some View {
        rowContent
            .padding(.leading, contentLeadingPadding)
            .padding(.trailing, Metrics.horizontalPadding)
            .padding(.top, state.level == 0 ? Metrics.verticalPadding : Metrics.nestedTopPadding)
            .padding(.bottom, Metrics.verticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leading) {
                threadRails
                    .padding(.leading, Metrics.horizontalPadding)
            }
    }

    @ViewBuilder
    private var rowControls: some View {
        EmptyView()
    }

    private var visibleGuideCount: Int {
        min(max(state.level, 0), Metrics.maxVisibleGuides)
    }

    private var contentLeadingPadding: CGFloat {
        guard visibleGuideCount > 0 else { return Metrics.horizontalPadding }
        let railWidth = CGFloat(visibleGuideCount) * railHairlineWidth
        let railSpacing = CGFloat(max(visibleGuideCount - 1, 0)) * Metrics.railSpacing
        return Metrics.horizontalPadding + railWidth + railSpacing + Metrics.railContentSpacing
    }

    private var railHairlineWidth: CGFloat {
        1 / max(displayScale, 1)
    }

    private var threadRailsWidth: CGFloat {
        CGFloat(visibleGuideCount) * railHairlineWidth
            + CGFloat(max(visibleGuideCount - 1, 0)) * Metrics.railSpacing
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(state.author)
                    .scaledFont(.subheadline)
                    .bold()
                    .foregroundStyle(state.isPostAuthor ? AppColors.appTintColor : .primary)
                Text(state.age)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
                metadataSeparator
                if showsVoteControl {
                    inlineVoteControl
                }
                if state.visibility == .compact {
                    metadataSeparator
                    Image(systemName: "chevron.down")
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            commentText
                .transaction { transaction in
                    transaction.disablesAnimations = true
                }
        }
        .clipped()
    }

    @ViewBuilder
    private var threadRails: some View {
        if visibleGuideCount > 0 {
            ThreadRailStack(
                count: visibleGuideCount,
                spacing: Metrics.railSpacing,
                lineWidth: railHairlineWidth
            )
            .frame(width: threadRailsWidth)
        }
    }

    private var metadataSeparator: some View {
        Text("•")
            .scaledFont(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var showsVoteControl: Bool {
        state.canVote || state.canUnvote || state.isUpvoted
    }

    @ViewBuilder
    private var inlineVoteControl: some View {
        if state.canUnvote, state.isUpvoted {
            Button(action: onUnvote) {
                voteLabel
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Unvote")
        } else if state.canVote, !state.isUpvoted {
            Button(action: onUpvote) {
                voteLabel
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Upvote")
        } else {
            voteLabel
        }
    }

    private var voteLabel: some View {
        Image(systemName: state.isUpvoted ? "arrow.up.circle.fill" : "arrow.up")
            .scaledFont(.subheadline)
            .foregroundStyle(AppColors.upvotedColor)
            .accessibilityHidden(true)
    }

    private var commentText: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let styledText = state.styledText {
                Text(styledText)
                    .foregroundStyle(.primary)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }
}

private struct ThreadRailStack: View {
    let count: Int
    let spacing: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        Canvas { context, size in
            let style = StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
            let color = Color(uiColor: .separator)

            for index in 0..<count {
                let x = (lineWidth / 2) + CGFloat(index) * (lineWidth + spacing)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(color), style: style)
            }
        }
        .frame(maxHeight: .infinity)
        .accessibilityHidden(true)
    }
}

private struct CommentTopRevealModifier: ViewModifier {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        content
            .opacity(progress)
            .mask(alignment: .top) {
                GeometryReader { geometry in
                    Rectangle()
                        .frame(height: max(0, geometry.size.height * progress))
                        .frame(maxWidth: .infinity, alignment: .top)
                }
            }
    }
}

extension AnyTransition {
    static var commentTopReveal: AnyTransition {
        .modifier(
            active: CommentTopRevealModifier(progress: 0),
            identity: CommentTopRevealModifier(progress: 1)
        )
    }
}

/// Precomputes fonts for each inline presentation style so comment text scaling stays consistent.
@MainActor
private struct CommentFontProvider {
    private static var cache: [CGFloat: CommentFontProvider] = [:]

    private let base: Font
    private let bold: Font
    private let italic: Font
    private let boldItalic: Font
    private let code: Font
    private let codeBold: Font
    private let codeItalic: Font
    private let codeBoldItalic: Font

    static func cached(textScaling: CGFloat) -> CommentFontProvider {
        if let cached = cache[textScaling] {
            return cached
        }
        let provider = CommentFontProvider(textScaling: textScaling)
        cache[textScaling] = provider
        return provider
    }

    private init(textScaling: CGFloat) {
        let basePointSize = UIFont.preferredFont(forTextStyle: .callout).pointSize * textScaling
        let codePointSize = UIFont.preferredFont(forTextStyle: .subheadline).pointSize * textScaling

        base = Self.makeFont(size: basePointSize, weight: .regular, italic: false, monospaced: false)
        bold = Self.makeFont(size: basePointSize, weight: .semibold, italic: false, monospaced: false)
        italic = Self.makeFont(size: basePointSize, weight: .regular, italic: true, monospaced: false)
        boldItalic = Self.makeFont(size: basePointSize, weight: .semibold, italic: true, monospaced: false)

        code = Self.makeFont(size: codePointSize, weight: .regular, italic: false, monospaced: true)
        codeBold = Self.makeFont(size: codePointSize, weight: .semibold, italic: false, monospaced: true)
        codeItalic = Self.makeFont(size: codePointSize, weight: .regular, italic: true, monospaced: true)
        codeBoldItalic = Self.makeFont(size: codePointSize, weight: .semibold, italic: true, monospaced: true)
    }

    func font(isCode: Bool, isBold: Bool, isItalic: Bool) -> Font {
        switch (isCode, isBold, isItalic) {
        case (true, true, true):
            return codeBoldItalic
        case (true, true, false):
            return codeBold
        case (true, false, true):
            return codeItalic
        case (true, false, false):
            return code
        case (false, true, true):
            return boldItalic
        case (false, true, false):
            return bold
        case (false, false, true):
            return italic
        default:
            return base
        }
    }

    private static func makeFont(
        size: CGFloat,
        weight: UIFont.Weight,
        italic: Bool,
        monospaced: Bool
    ) -> Font {
        var font: UIFont
        if monospaced {
            font = UIFont.monospacedSystemFont(ofSize: size, weight: weight)
        } else {
            font = UIFont.systemFont(ofSize: size, weight: weight)
        }

        if italic {
            if let italicDescriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic) {
                font = UIFont(descriptor: italicDescriptor, size: size)
            } else {
                font = UIFont.italicSystemFont(ofSize: size)
            }
        }

        return Font(font)
    }
}

@MainActor
enum CommentTextCache {
    private struct BaseCacheKey: Hashable {
        let commentID: Int
        let textHash: Int
    }

    private struct StyledCacheKey: Hashable {
        let commentID: Int
        let textHash: Int
        let scale: Double
    }

    private static var baseCache: [BaseCacheKey: AttributedString] = [:]
    private static var styledCache: [StyledCacheKey: AttributedString] = [:]

    static func prewarm(comments: ArraySlice<Comment>, textScaling: CGFloat, chunkSize: Int = .max) async {
        for (index, comment) in comments.enumerated() where comment.visibility == .visible {
            _ = styledText(for: comment, textScaling: textScaling)
            if index > 0, index.isMultiple(of: chunkSize) {
                await Task.yield()
            }
        }
    }

    static func styledText(for comment: Comment, textScaling: CGFloat) -> AttributedString {
        let textHash = comment.text.hashValue
        let key = StyledCacheKey(
            commentID: comment.id,
            textHash: textHash,
            scale: Double(textScaling)
        )
        if let cached = styledCache[key] {
            return cached
        }

        var attributed = baseText(for: comment, textHash: textHash)
        let fontProvider = CommentFontProvider.cached(textScaling: textScaling)
        let linkColor = AppColors.appTintColor

        for run in attributed.runs {
            let range = run.range
            let intents = run.inlinePresentationIntent ?? []
            attributed[range].font = fontProvider.font(
                isCode: intents.contains(.code),
                isBold: intents.contains(.stronglyEmphasized),
                isItalic: intents.contains(.emphasized)
            )
        }

        for run in attributed.runs where run.link != nil {
            attributed[run.range].foregroundColor = linkColor
        }

        styledCache[key] = attributed
        return attributed
    }

    private static func baseText(for comment: Comment, textHash: Int) -> AttributedString {
        let key = BaseCacheKey(commentID: comment.id, textHash: textHash)
        if let cached = baseCache[key] {
            return cached
        }

        let parsed = CommentHTMLParser.parseHTMLText(comment.text)
        baseCache[key] = parsed
        return parsed
    }
}
