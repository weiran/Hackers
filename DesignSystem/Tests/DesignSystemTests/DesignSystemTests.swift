//
//  DesignSystemTests.swift
//  DesignSystemTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import DesignSystem
import Domain
import SwiftUI
import Testing
import UIKit

@Suite("DesignSystem Tests")
struct DesignSystemTests {
    @MainActor
    @Test("Vote button keeps its height while submitting")
    func voteButtonLoadingHeight() {
        let style = VoteButtonStyle(
            showScore: false,
            iconFont: .subheadline,
            spacing: 0,
            defaultIconName: "arrow.up.circle",
            upvotedIconName: "arrow.up.circle.fill",
            defaultColor: .secondary
        )
        let idleSize = voteButtonSize(
            state: VotingState(isUpvoted: false, canVote: true),
            style: style
        )
        let submittingSize = voteButtonSize(
            state: VotingState(isUpvoted: true, canVote: false, canUnvote: true, isVoting: true),
            style: style
        )

        #expect(submittingSize.height == idleSize.height)
    }

    @MainActor
    private func voteButtonSize(state: VotingState, style: VoteButtonStyle) -> CGSize {
        let controller = UIHostingController(
            rootView: VoteButton(votingState: state, style: style, action: {})
                .buttonStyle(.plain)
        )
        return controller.sizeThatFits(in: CGSize(width: 200, height: 200))
    }
}
