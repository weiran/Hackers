//
//  CommentComposerModelTests.swift
//  CommentsTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Comments
import Domain
import Foundation
import Testing

@Suite("CommentComposerModel")
@MainActor
struct CommentComposerModelTests {
    @Test("Draft preview uses the first non-empty line")
    func draftPreview() {
        let model = CommentComposerModel()

        model.text = "  \n\nfirst line\nsecond line"
        #expect(model.draftPreview == "first line")
        #expect(model.hasDraft)
        #expect(model.canPost)

        model.text = "   \n\t\n"
        #expect(!model.hasDraft)
        #expect(model.draftPreview == nil)
        #expect(!model.canPost)
    }

    @Test("Collapse preserves draft and target; cancel clears everything")
    func collapseAndCancel() {
        let model = CommentComposerModel()
        model.activateReply(commentID: 5, author: "alice")
        model.text = "draft"

        model.collapsePreservingDraft()
        #expect(!model.isExpanded)
        #expect(model.text == "draft")
        #expect(model.target == .reply(commentID: 5, author: "alice"))

        model.expand()
        #expect(model.isExpanded)

        model.cancel()
        #expect(model.text.isEmpty)
        #expect(model.target == .story)
        #expect(!model.isExpanded)
        #expect(model.inlineError == nil)
    }

    @Test("Dirty target switches preserve the draft and retarget immediately")
    func dirtyTargetSwitch() {
        let model = CommentComposerModel()
        model.activateReply(commentID: 5, author: "alice")
        model.text = "precious draft"

        model.activateReply(commentID: 7, author: "bob")
        #expect(model.alert == nil)
        #expect(model.text == "precious draft")
        #expect(model.target == .reply(commentID: 7, author: "bob"))
        #expect(model.isExpanded)

        // Switching a dirty reply draft back to a top-level comment also
        // preserves the text while changing the target.
        model.text = "another draft"
        model.activateTopLevel()
        #expect(model.alert == nil)
        #expect(model.text == "another draft")
        #expect(model.target == .story)
    }

    @Test("Re-activating the same reply target just expands")
    func sameTargetReactivation() {
        let model = CommentComposerModel()
        model.activateReply(commentID: 5, author: "alice")
        model.text = "draft"
        model.collapsePreservingDraft()

        model.activateReply(commentID: 5, author: "alice")
        #expect(model.alert == nil)
        #expect(model.isExpanded)
        #expect(model.text == "draft")
    }

    @Test("Posting locks editing and state transitions restore it")
    func submissionLifecycle() {
        let model = CommentComposerModel()
        model.text = "draft"
        model.expand()

        model.beginPosting()
        #expect(model.isPosting)
        #expect(!model.canPost)
        model.collapsePreservingDraft()
        #expect(model.isExpanded, "Focus loss must not collapse mid-posting")
        model.cancel()

        model.postingFailed(message: "failed")
        #expect(!model.isPosting)
        #expect(model.inlineError == "failed")
        #expect(model.canPost, "Editing after a definite failure re-enables posting")
        #expect(model.text == "draft")
        #expect(model.isExpanded)

        model.text += " more"
        #expect(model.inlineError == nil, "Editing clears the stale error")

        model.beginPosting()
        let attempt = CommentSubmissionAttempt(
            request: CommentSubmissionRequest(
                storyID: 1, parentID: 1, expectedAuthor: "alice", text: "draft more"
            ),
            baselineChildIDs: [],
            startedAt: Date()
        )
        model.postingBecameUnconfirmed(attempt: attempt)
        #expect(model.submissionState == .outcomeUnknown(attempt))
        #expect(model.alert == .outcomeUnknown)
        #expect(!model.canPost, "Outcome-unknown blocks normal posting")
        #expect(model.text == "draft more", "Draft is preserved")

        model.outcomeUnknownStillUnresolved()
        #expect(model.alert == .outcomeUnknown)

        model.outcomeUnknownResolved()
        #expect(model.submissionState == .idle)
        #expect(model.text.isEmpty)
        #expect(!model.isExpanded)
    }

    @Test("Session expiry preserves the draft for a later re-login")
    func sessionExpiry() {
        let model = CommentComposerModel()
        model.activateReply(commentID: 5, author: "alice")
        model.text = "draft"
        model.beginPosting()

        model.sessionDidExpire()

        #expect(model.submissionState == .idle)
        #expect(model.text == "draft")
        #expect(model.target == .reply(commentID: 5, author: "alice"))
        #expect(!model.isExpanded, "The preserved draft stays collapsed")
    }
}
