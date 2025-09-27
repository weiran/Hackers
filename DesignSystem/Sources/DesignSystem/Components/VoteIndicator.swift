//
//  VoteIndicator.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import SwiftUI

public struct VoteIndicator: View {
    private let votingState: VotingState
    private let style: VoteIndicatorStyle

    public init(
        votingState: VotingState,
        style: VoteIndicatorStyle = .default,
    ) {
        self.votingState = votingState
        self.style = style
    }

    public var body: some View {
        HStack(spacing: style.spacing) {
            if style.showScore, let score = votingState.score {
                Text("\(score)")
                    .scaledFont(style.scoreFont)
                    .foregroundColor(scoreColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: score)
            }

            Image(systemName: iconName)
                .scaledFont(style.iconFont)
                .foregroundColor(iconColor)
                .scaleEffect(style.iconScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: votingState.isUpvoted)
                .accessibilityHidden(true)
        }
        .animation(.easeInOut(duration: 0.2), value: votingState.canVote)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel({ () -> String in
            let base = (votingState.score != nil) ? "\(votingState.score!) points" : "Votes"
            return votingState.isUpvoted ? base + ", upvoted" : base
        }())
    }

    private var iconName: String {
        votingState.isUpvoted ? style.upvotedIconName : style.unvotedIconName
    }

    private var iconColor: Color {
        votingState.isUpvoted ? style.upvotedColor : style.defaultColor
    }

    private var scoreColor: Color {
        if votingState.isUpvoted {
            style.upvotedColor
        } else {
            style.defaultColor
        }
    }
}

public struct VoteIndicatorStyle: Sendable {
    public let showScore: Bool
    public let iconFont: Font
    public let scoreFont: Font
    public let spacing: CGFloat
    public let iconScale: CGFloat
    public let unvotedIconName: String
    public let upvotedIconName: String
    public let defaultColor: Color
    public let upvotedColor: Color

    public init(
        showScore: Bool = true,
        iconFont: Font = .body,
        scoreFont: Font = .caption,
        spacing: CGFloat = 4,
        iconScale: CGFloat = 1.0,
        unvotedIconName: String = "arrow.up",
        upvotedIconName: String = "arrow.up.circle.fill",
        defaultColor: Color = .secondary,
        upvotedColor: Color = AppColors.upvotedColor,
    ) {
        self.showScore = showScore
        self.iconFont = iconFont
        self.scoreFont = scoreFont
        self.spacing = spacing
        self.iconScale = iconScale
        self.unvotedIconName = unvotedIconName
        self.upvotedIconName = upvotedIconName
        self.defaultColor = defaultColor
        self.upvotedColor = upvotedColor
    }

    public static let `default` = VoteIndicatorStyle()

    public static let compact = VoteIndicatorStyle(
        showScore: false,
        iconFont: .caption,
        spacing: 0,
        iconScale: 0.8,
    )

    public static let large = VoteIndicatorStyle(
        iconFont: .title3,
        scoreFont: .body,
        spacing: 6,
        iconScale: 1.2,
    )
}
