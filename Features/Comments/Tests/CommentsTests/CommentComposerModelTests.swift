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
    @Test("New model starts collapsed on the story target with no draft")
    func initialState() {
        let model = CommentComposerModel()

        #expect(model.text.isEmpty)
        #expect(model.target == .story)
        #expect(!model.isExpanded)
        #expect(model.submissionState == .idle)
        #expect(model.inlineError == nil)
        #expect(model.alert == nil)
        #expect(!model.hasDraft)
        #expect(!model.canPost)
        #expect(model.draftPreview == nil)
        #expect(model.replyUsername == nil)
    }

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

    @Test("Empty-draft target switches are immediate")
    func cleanTargetSwitch() {
        let model = CommentComposerModel()

        model.activateReply(commentID: 5, author: "alice")
        #expect(model.target == .reply(commentID: 5, author: "alice"))
        #expect(model.isExpanded)
        #expect(model.replyUsername == "alice")

        model.activateReply(commentID: 7, author: "bob")
        #expect(model.target == .reply(commentID: 7, author: "bob"))

        model.activateTopLevel()
        #expect(model.target == .story)
        #expect(model.replyUsername == nil)
    }

    @Test("Dirty target switches require confirmation")
    func dirtyTargetSwitch() {
        let model = CommentComposerModel()
        model.activateReply(commentID: 5, author: "alice")
        model.text = "precious draft"

        model.activateReply(commentID: 7, author: "bob")
        #expect(model.alert == .discardDraft(newTarget: .reply(commentID: 7, author: "bob")))
        #expect(model.text == "precious draft", "Keep Editing default preserves the draft")
        #expect(model.target == .reply(commentID: 5, author: "alice"))

        model.keepCurrentDraft()
        #expect(model.alert == nil)
        #expect(model.text == "precious draft")
        #expect(model.target == .reply(commentID: 5, author: "alice"))

        model.activateReply(commentID: 7, author: "bob")
        model.confirmTargetReplacement()
        #expect(model.text.isEmpty)
        #expect(model.target == .reply(commentID: 7, author: "bob"))
        #expect(model.isExpanded)

        // Switching a dirty reply draft back to a top-level comment works too.
        model.text = "another draft"
        model.activateTopLevel()
        #expect(model.alert == .discardDraft(newTarget: .story))
        model.confirmTargetReplacement()
        #expect(model.text.isEmpty)
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

    @Test("Success clears and collapses the composer")
    func postingSucceeded() {
        let model = CommentComposerModel()
        model.activateReply(commentID: 5, author: "alice")
        model.text = "draft"
        model.beginPosting()

        model.postingSucceeded()

        #expect(model.text.isEmpty)
        #expect(model.target == .story)
        #expect(model.submissionState == .idle)
        #expect(!model.isExpanded)
        #expect(model.inlineError == nil)
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
