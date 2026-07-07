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
            .padding(.leading, CGFloat(16 + min(state.level, 6) * 14))
            .padding(.trailing, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var rowControls: some View {
        EmptyView()
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(state.author)
                    .scaledFont(.subheadline)
                    .bold()
                    .foregroundStyle(state.isPostAuthor ? AppColors.appTintColor : .primary)
                Text(state.age)
                    .scaledFont(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if state.isUpvoted {
                    VoteIndicator(
                        votingState: VotingState(
                            isUpvoted: state.isUpvoted,
                            score: nil,
                            canVote: state.canVote,
                            canUnvote: state.canUnvote
                        ),
                        style: VoteIndicatorStyle(showScore: false, iconFont: .body, iconScale: 1.0),
                    )
                }
                if state.visibility == .compact {
                    Image(systemName: "chevron.down")
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            if let styledText = state.styledText {
                Text(styledText)
                    .foregroundStyle(.primary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipped()
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
