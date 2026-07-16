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

    @Test("DesignSystem is a singleton")
    func singleton() {
        let designSystem1 = DesignSystem.shared
        let designSystem2 = DesignSystem.shared

        #expect(designSystem1 === designSystem2, "DesignSystem should be a singleton")
    }

    @Test("DesignSystem singleton consistency")
    func singletonConsistency() {
        // Test that the singleton returns the same instance across multiple calls
        let instances = (0 ..< 5).map { _ in DesignSystem.shared }

        for index in 1 ..< instances.count {
            #expect(instances[0] === instances[index], "All instances should be the same")
        }
    }

    @Test("DesignSystem thread safety")
    func threadSafety() async {
        // Test concurrent access to the singleton
        await withTaskGroup(of: DesignSystem.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    DesignSystem.shared
                }
            }

            var instances: [DesignSystem] = []
            for await instance in group {
                instances.append(instance)
            }

            // All instances should be the same
            for index in 1 ..< instances.count {
                #expect(instances[0] === instances[index], "Concurrent access should return same instance")
            }
        }
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
