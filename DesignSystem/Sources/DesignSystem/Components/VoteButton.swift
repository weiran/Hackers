//
//  VoteButton.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import SwiftUI

public struct VoteButton: View {
    private let votingState: VotingState
    private let action: @Sendable () -> Void
    private let style: VoteButtonStyle

    public init(
        votingState: VotingState,
        style: VoteButtonStyle = .default,
        action: @escaping @Sendable () -> Void,
    ) {
        self.votingState = votingState
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: style.spacing) {
                if votingState.isVoting {
                    ProgressView()
                        .scaleEffect(style.progressScale)
                        .foregroundStyle(style.foregroundColor(for: votingState))
                } else {
                    Image(systemName: iconName)
                        .scaledFont(style.iconFont)
                        .foregroundStyle(style.foregroundColor(for: votingState))
                        .accessibilityHidden(true)
                }

                if style.showScore, let score = votingState.score {
                    Text("\(score)")
                        .scaledFont(style.scoreFont)
                        .foregroundStyle(style.foregroundColor(for: votingState))
                }
            }
        }
        .disabled((!votingState.canVote && !votingState.canUnvote) || votingState.isVoting)
        .scaleEffect(votingState.isVoting ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: votingState.isVoting)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityValue({ () -> String in
            if let score = votingState.score { return "\(score) points" }
            return ""
        }())
    }

    private var iconName: String {
        if votingState.isUpvoted {
            style.upvotedIconName
        } else {
            style.defaultIconName
        }
    }

    private var accessibilityLabelText: String {
        if votingState.isUpvoted {
            return votingState.canUnvote ? "Unvote" : "Upvoted"
        }
        return "Upvote"
    }

    private var accessibilityHintText: String {
        if votingState.isUpvoted {
            return votingState.canUnvote ? "Double-tap to unvote" : "Already upvoted"
        }
        return votingState.canVote ? "Double-tap to upvote" : "Voting unavailable"
    }
}

public struct VoteButtonStyle: Sendable {
    public let showScore: Bool
    public let iconFont: Font
    public let scoreFont: Font
    public let spacing: CGFloat
    public let progressScale: CGFloat
    public let defaultIconName: String
    public let upvotedIconName: String
    public let defaultColor: Color
    public let upvotedColor: Color
    public let disabledColor: Color

    public init(
        showScore: Bool = true,
        iconFont: Font = .body,
        scoreFont: Font = .caption,
        spacing: CGFloat = 4,
        progressScale: CGFloat = 0.8,
        defaultIconName: String = "arrow.up",
        upvotedIconName: String = "arrow.up.circle.fill",
        defaultColor: Color = .primary,
        upvotedColor: Color = AppColors.upvotedColor,
        disabledColor: Color = .secondary,
    ) {
        self.showScore = showScore
        self.iconFont = iconFont
        self.scoreFont = scoreFont
        self.spacing = spacing
        self.progressScale = progressScale
        self.defaultIconName = defaultIconName
        self.upvotedIconName = upvotedIconName
        self.defaultColor = defaultColor
        self.upvotedColor = upvotedColor
        self.disabledColor = disabledColor
    }

    public func foregroundColor(for state: VotingState) -> Color {
        if !state.canVote {
            disabledColor
        } else if state.isUpvoted {
            upvotedColor
        } else {
            defaultColor
        }
    }

    public static let `default` = VoteButtonStyle()

    public static let compact = VoteButtonStyle(
        showScore: false,
        iconFont: .caption,
        spacing: 0,
    )

    public static let inline = VoteButtonStyle(
        iconFont: .subheadline,
        scoreFont: .subheadline,
        spacing: 6,
    )
}
