//
//  VoteIndicator.swift
//  DesignSystem
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import Domain

public struct VoteIndicator: View {
    private let votingState: VotingState
    private let style: VoteIndicatorStyle

    public init(
        votingState: VotingState,
        style: VoteIndicatorStyle = .default
    ) {
        self.votingState = votingState
        self.style = style
    }

    public var body: some View {
        HStack(spacing: style.spacing) {
            if votingState.isUpvoted {
                Image(systemName: style.upvotedIconName)
                    .font(style.iconFont)
                    .foregroundColor(style.upvotedColor)
                    .scaleEffect(style.iconScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: votingState.isUpvoted)
            }

            if style.showScore, let score = votingState.score {
                Text("\(score)")
                    .font(style.scoreFont)
                    .foregroundColor(scoreColor)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: score)
            }
        }
        .opacity(votingState.canVote ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.2), value: votingState.canVote)
    }

    private var scoreColor: Color {
        if votingState.isUpvoted {
            return style.upvotedColor
        } else {
            return style.defaultColor
        }
    }
}

public struct VoteIndicatorStyle: Sendable {
    public let showScore: Bool
    public let iconFont: Font
    public let scoreFont: Font
    public let spacing: CGFloat
    public let iconScale: CGFloat
    public let upvotedIconName: String
    public let defaultColor: Color
    public let upvotedColor: Color

    public init(
        showScore: Bool = true,
        iconFont: Font = .body,
        scoreFont: Font = .caption,
        spacing: CGFloat = 4,
        iconScale: CGFloat = 1.0,
        upvotedIconName: String = "arrow.up.circle.fill",
        defaultColor: Color = .secondary,
        upvotedColor: Color = AppColors.upvotedColor
    ) {
        self.showScore = showScore
        self.iconFont = iconFont
        self.scoreFont = scoreFont
        self.spacing = spacing
        self.iconScale = iconScale
        self.upvotedIconName = upvotedIconName
        self.defaultColor = defaultColor
        self.upvotedColor = upvotedColor
    }

    public static let `default` = VoteIndicatorStyle()

    public static let compact = VoteIndicatorStyle(
        showScore: false,
        iconFont: .caption,
        spacing: 0,
        iconScale: 0.8
    )

    public static let large = VoteIndicatorStyle(
        iconFont: .title3,
        scoreFont: .body,
        spacing: 6,
        iconScale: 1.2
    )
}
