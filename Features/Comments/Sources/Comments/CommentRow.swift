//
//  CommentRow.swift
//  Comments
//
//  Extracted from CommentsComponents to keep file size manageable.
//

import DesignSystem
import Domain
import Observation
import Shared
import SwiftUI
import UIKit

struct CommentRow: View {
    @Bindable var comment: Comment
    let post: Post
    let votingViewModel: VotingViewModel
    let onToggle: () -> Void
    let onHide: () -> Void
    @Environment(\.textScaling) private var textScaling

    private var baseCommentText: AttributedString {
        if let cached = comment.parsedText {
            return cached
        }

        let parsed = CommentHTMLParser.parseHTMLText(comment.text)
        comment.parsedText = parsed
        return parsed
    }

    private func styledText(for textScaling: CGFloat) -> AttributedString {
        StyledCommentTextCache.text(
            commentID: comment.id,
            textScaling: textScaling,
            baseText: baseCommentText
        )
    }

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(comment.by)
                        .scaledFont(.subheadline)
                        .bold()
                        .foregroundStyle(comment.by == post.by ? AppColors.appTintColor : .primary)
                    Text(comment.age)
                        .scaledFont(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if comment.upvoted {
                        VoteIndicator(
                            votingState: VotingState(
                                isUpvoted: comment.upvoted,
                                score: nil,
                                canVote: comment.voteLinks?.upvote != nil,
                                canUnvote: comment.voteLinks?.unvote != nil,
                                isVoting: votingViewModel.isVoting,
                                error: votingViewModel.lastError,
                            ),
                            style: VoteIndicatorStyle(showScore: false, iconFont: .body, iconScale: 1.0),
                        )
                    }
                    if comment.visibility == .compact {
                        Image(systemName: "chevron.down")
                            .scaledFont(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                if comment.visibility == .visible {
                    Text(styledText(for: textScaling))
                        .foregroundStyle(.primary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowInsets([.top, .bottom, .trailing], 16)
        .listRowInsets([.leading], CGFloat((comment.level + 1) * 16))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(comment.visibility == .visible ? "Tap to collapse" : "Tap to expand")
        .contextMenu {
            VotingContextMenuItems.commentVotingMenuItems(
                for: comment,
                onVote: {
                    Task { await votingViewModel.upvote(comment: comment, in: post) }
                },
                onUnvote: {
                    Task { await votingViewModel.unvote(comment: comment, in: post) }
                }
            )
            Button { UIPasteboard.general.string = comment.text.strippingHTML() } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Divider()
            Button { ContentSharePresenter.shared.shareComment(comment) } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .id(String(comment.id) + String(comment.visibility.rawValue))
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
private enum StyledCommentTextCache {
    private struct CacheKey: Hashable {
        let commentID: Int
        let scale: CGFloat
    }

    private struct Entry {
        let base: AttributedString
        let styled: AttributedString
    }

    private static var cache: [CacheKey: Entry] = [:]

    static func text(commentID: Int, textScaling: CGFloat, baseText: AttributedString) -> AttributedString {
        let key = CacheKey(commentID: commentID, scale: textScaling)
        if let cached = cache[key], cached.base == baseText {
            return cached.styled
        }

        var attributed = baseText
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

        cache[key] = Entry(base: baseText, styled: attributed)
        return attributed
    }
}
