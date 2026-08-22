//
//  CommentRow.swift
//  Comments
//
//  Extracted from CommentsComponents to keep file size manageable.
//

import DesignSystem
import Domain
import Shared
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
    let isVoting: Bool
    let isAuthenticated: Bool
    let canVote: Bool
    let canUnvote: Bool
    let canReply: Bool
    let isCommentSubmissionInProgress: Bool
    let styledText: AttributedString?
}

struct CommentRow: View {
    private enum Metrics {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 16
        static let nestedTopPadding: CGFloat = 12
        static let railSpacing: CGFloat = 24
        static let railContentSpacing: CGFloat = 24
        static let maxVisibleGuides = 5
    }

    @Environment(\.displayScale) private var displayScale

    let state: CommentRowState
    let onToggle: () -> Void
    let onUpvote: () -> Void
    let onUnvote: () -> Void
    let onCopy: () -> Void
    let onShare: () -> Void
    var onReply: (() -> Void)?
    var onInteraction: (() -> Void)?

    var body: some View {
        rowDisplay
            .contentShape(.interaction, Rectangle())
            .onTapGesture(perform: handleToggle)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(AccessibilityIdentifier.Comments.comment(state.id))
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(state.visibility == .visible ? "Tap to collapse" : "Tap to expand")
            .accessibilityAction(.default, handleToggle)
            .if(state.canReply) { row in
                row.accessibilityAction(named: Text("Reply to \(state.author)")) {
                    onReply?()
                }
            }
            .contextMenu {
                if state.isAuthenticated, state.canVote, !state.isUpvoted {
                    Button {
                        onInteraction?()
                        onUpvote()
                    } label: {
                        Label("Upvote", systemImage: "arrow.up")
                    }
                    .disabled(state.isVoting)
                }
                if state.isAuthenticated, state.canUnvote, state.isUpvoted {
                    Button {
                        onInteraction?()
                        onUnvote()
                    } label: {
                        Label("Unvote", systemImage: "arrow.uturn.down")
                    }
                    .disabled(state.isVoting)
                }
                if state.canReply {
                    Button(action: { onReply?() }) {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                    }
                    .disabled(state.isCommentSubmissionInProgress)
                }
                Divider()
                Button {
                    onInteraction?()
                    onCopy()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                Divider()
                Button {
                    onInteraction?()
                    onShare()
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            } preview: {
                contextMenuPreview
            }
    }

    /// The default preview snapshots the live row out of the lazy scroll
    /// container, which cancels the lift and produces a transparent,
    /// overlapping snapshot. An explicit opaque preview avoids both.
    private var contextMenuPreview: some View {
        rowDisplay
            .frame(width: UIScreen.main.bounds.width)
            .background(AppColors.background)
    }

    private func handleToggle() {
        onInteraction?()
        onToggle()
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
                    .lineLimit(1)
                    .truncationMode(.tail)
                if showsVoteControl {
                    metadataSeparator
                    inlineVoteControl
                }
                if state.canReply {
                    metadataSeparator
                    inlineReplyControl
                }
                Spacer(minLength: 12)
                Text(shortAge)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .accessibilityLabel(state.age)
            }
            commentText
                .transaction { transaction in
                    transaction.disablesAnimations = true
                }
        }
        .clipped()
    }

    /// Reply must stay available even when the row has no vote control; the
    /// buttons consume taps so they never trigger row collapse.
    private var inlineReplyControl: some View {
        Button {
            onReply?()
        } label: {
            Image(systemName: "arrowshape.turn.up.left")
                .scaledFont(.subheadline)
                .foregroundStyle(.secondary)
                .frame(minWidth: 30, minHeight: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(state.isCommentSubmissionInProgress)
        .accessibilityLabel("Reply to \(state.author)")
        .accessibilityIdentifier(AccessibilityIdentifier.Comments.reply(state.id))
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
        state.isAuthenticated && (state.canVote || state.canUnvote || state.isUpvoted)
    }

    private var shortAge: String {
        let parts = state.age.split(separator: " ")
        guard
            parts.count >= 2,
            let value = Int(parts[0])
        else {
            return state.age
        }

        let unit = parts[1].lowercased()
        if unit.hasPrefix("minute") { return "\(value)m" }
        if unit.hasPrefix("hour") { return "\(value)h" }
        if unit.hasPrefix("day") { return "\(value)d" }
        if unit.hasPrefix("month") { return "\(value)mo" }
        if unit.hasPrefix("year") { return "\(value)y" }
        return state.age
    }

    @ViewBuilder
    private var inlineVoteControl: some View {
        VoteButton(
            votingState: VotingState(
                isUpvoted: state.isUpvoted,
                canVote: !state.isUpvoted && state.canVote,
                canUnvote: state.isUpvoted && state.canUnvote,
                isVoting: state.isVoting
            ),
            style: .commentInline,
            action: {
                onInteraction?()
                if state.isUpvoted {
                    onUnvote()
                } else {
                    onUpvote()
                }
            }
        )
        .buttonStyle(.plain)
        .accessibilityIdentifier(AccessibilityIdentifier.Comments.vote(state.id))
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

private extension VoteButtonStyle {
    static let commentInline = VoteButtonStyle(
        showScore: false,
        iconFont: .subheadline,
        spacing: 0,
        defaultIconName: "arrow.up.circle",
        upvotedIconName: "arrow.up.circle.fill",
        defaultColor: .secondary
    )
}

private struct ThreadRailStack: View {
    let count: Int
    let spacing: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { _ in
                Divider()
                    .frame(width: lineWidth)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: CGFloat(count) * lineWidth + CGFloat(max(count - 1, 0)) * spacing)
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
            attributed[run.range].underlineStyle = .single
        }

        applyParagraphStyling(to: &attributed)

        styledCache[key] = attributed
        return attributed
    }

    /// Paragraph metrics are a presentation concern and are applied only after
    /// semantic parsing has reached the MainActor-backed Comments feature.
    private static func applyParagraphStyling(to attributed: inout AttributedString) {
        guard !attributed.characters.isEmpty else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.5
        paragraphStyle.paragraphSpacing = 20.0

        let fullRange = attributed.startIndex ..< attributed.endIndex
        let paragraphAttributes = AttributeContainer([
            .paragraphStyle: paragraphStyle
        ])
        attributed[fullRange].mergeAttributes(paragraphAttributes)
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
