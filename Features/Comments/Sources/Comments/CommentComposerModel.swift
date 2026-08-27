//
//  CommentComposerModel.swift
//  Comments
//
//  State machine for the shared bottom comment composer. Drafts live here,
//  view-locally; nothing is persisted.
//

import Domain
import Foundation
import Observation
import SwiftUI

public enum CommentComposerTarget: Equatable, Sendable {
    case story
    case reply(commentID: Int, author: String)
}

enum CommentComposerPresentation: Equatable, Sendable {
    case collapsed
    case expanded
}

enum CommentComposerSubmissionState: Equatable, Sendable {
    case idle
    case posting
    case outcomeUnknown(CommentSubmissionAttempt)
}

enum CommentComposerAlert: Identifiable, Equatable {
    case discardDraft(newTarget: CommentComposerTarget)
    case outcomeUnknown

    var id: String {
        switch self {
        case .discardDraft:
            "discardDraft"
        case .outcomeUnknown:
            "outcomeUnknown"
        }
    }
}

@MainActor
@Observable
public final class CommentComposerModel {
    var text = "" {
        didSet {
            if oldValue != text { inlineError = nil }
        }
    }

    var target: CommentComposerTarget = .story
    var presentation: CommentComposerPresentation = .collapsed
    var submissionState: CommentComposerSubmissionState = .idle
    var inlineError: String?
    var alert: CommentComposerAlert?

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasDraft: Bool {
        !trimmedText.isEmpty
    }

    var isPosting: Bool {
        if case .posting = submissionState { return true }
        return false
    }

    var isExpanded: Bool {
        presentation == .expanded
    }

    var replyUsername: String? {
        guard case let .reply(_, author) = target else { return nil }
        return author
    }

    /// First non-empty line of the draft for the collapsed preview.
    var draftPreview: String? {
        guard hasDraft else { return nil }
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }

    var canPost: Bool {
        hasDraft && submissionState == .idle
    }

    // MARK: - Activation

    func activateTopLevel() {
        guard !isPosting else { return }
        if hasDraft, target != .story {
            alert = .discardDraft(newTarget: .story)
            return
        }
        target = .story
        presentation = .expanded
    }

    func activateReply(commentID: Int, author: String) {
        guard !isPosting else { return }
        let newTarget: CommentComposerTarget = .reply(commentID: commentID, author: author)
        if target == newTarget {
            presentation = .expanded
            return
        }
        if hasDraft {
            alert = .discardDraft(newTarget: newTarget)
            return
        }
        text = ""
        target = newTarget
        presentation = .expanded
    }

    /// Applies a confirmed discard: clears the old draft and switches to the
    /// pending target from the discard alert.
    func confirmTargetReplacement() {
        guard case let .discardDraft(newTarget) = alert else { return }
        alert = nil
        text = ""
        inlineError = nil
        target = newTarget
        presentation = .expanded
    }

    func keepCurrentDraft() {
        alert = nil
    }

    // MARK: - Presentation

    func expand() {
        guard !isPosting else { return }
        presentation = .expanded
    }

    func collapsePreservingDraft() {
        guard !isPosting else { return }
        presentation = .collapsed
    }

    func cancel() {
        guard !isPosting else { return }
        text = ""
        target = .story
        inlineError = nil
        submissionState = .idle
        presentation = .collapsed
    }

    // MARK: - Submission lifecycle

    func beginPosting() {
        submissionState = .posting
        inlineError = nil
    }

    func postingFailed(message: String) {
        submissionState = .idle
        inlineError = message
    }

    func postingBecameUnconfirmed(attempt: CommentSubmissionAttempt) {
        submissionState = .outcomeUnknown(attempt)
        alert = .outcomeUnknown
    }

    func postingSucceeded() {
        text = ""
        target = .story
        inlineError = nil
        submissionState = .idle
        presentation = .collapsed
    }

    /// Keeps the draft and target after a session-expiry login presentation;
    /// the composer collapses and submission state resets so a later attempt
    /// can proceed cleanly.
    func sessionDidExpire() {
        submissionState = .idle
        inlineError = nil
        presentation = .collapsed
    }

    /// Clears the outcome-unknown state after a successful reconciliation,
    /// behaving like a normal success.
    func outcomeUnknownResolved() {
        postingSucceeded()
    }

    /// Keeps the draft and re-presents the warning after reconciliation
    /// failed to find the comment.
    func outcomeUnknownStillUnresolved() {
        alert = .outcomeUnknown
    }
}

/// The transaction animation every composer expansion/collapse must run in,
/// so the glass capsule tweens between its pill and card shapes no matter
/// which caller mutated the presentation. Callers supply their Reduce Motion
/// environment value; the composer view uses the same helper.
enum ComposerMotion {
    /// Shared motion curve for the composer capsule growth AND the keyboard
    /// viewport resize (mirrored in the app target's sheet). Identical curves
    /// let the capsule read as glued to the keyboard's top edge while it
    /// grows, matching message-bar-style input accessories.
    static func animation(isReducedMotion: Bool) -> Animation {
        if isReducedMotion {
            .easeInOut(duration: 0.2)
        } else {
            .easeInOut(duration: 0.25)
        }
    }
}
