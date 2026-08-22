//
//  CommentComposerView.swift
//  Comments
//
//  The shared bottom composer for top-level comments and replies.
//

import DesignSystem
import Domain
import Shared
import SwiftUI

struct CommentComposerView: View {
    private enum Metrics {
        static let cardHorizontalPadding: CGFloat = 8
        static let cardVerticalPadding: CGFloat = 6
        static let cardTopPadding: CGFloat = 9
        static let editorTopPadding: CGFloat = 8
        // Match the editor's visible horizontal inset to the card's 6pt inset
        // plus the editor's 8pt top inset.
        static let editorHorizontalPadding: CGFloat = cardVerticalPadding + editorTopPadding
    }

    @Bindable var model: CommentComposerModel
    let onSubmit: () -> Void

    @FocusState private var isEditorFocused: Bool

    var body: some View {
        if model.isExpanded {
            expandedComposer
                .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            collapsedComposer
        }
    }

    // MARK: - Collapsed

    private var collapsedComposer: some View {
        Button {
            model.expand()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                if let username = model.replyUsername {
                    Text("Replying to \(username)")
                        .scaledFont(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Text(model.draftPreview ?? "Add a comment…")
                    .scaledFont(.subheadline)
                    .foregroundStyle(
                        model.draftPreview == nil
                            ? Color.primary.opacity(0.72)
                            : Color.primary
                    )
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerCollapsed)
    }

    // MARK: - Expanded

    private var expandedComposer: some View {
        GlassEffectContainer(spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                if let username = model.replyUsername {
                    Text("Replying to \(username)")
                        .scaledFont(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Metrics.editorHorizontalPadding)
                        .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerReplyLabel)
                }

                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        if model.text.isEmpty {
                            Text("Add a comment…")
                                .scaledFont(.callout)
                                .foregroundStyle(Color.primary.opacity(0.72))
                                .padding(.top, Metrics.editorTopPadding)
                                .padding(.horizontal, Metrics.editorHorizontalPadding)
                                .padding(.bottom, 4)
                                .allowsHitTesting(false)
                        }

                        TextField(
                            "",
                            text: Binding(
                                get: { model.text },
                                set: { newValue in
                                    // Keep the editor focused while the post is
                                    // in flight, but ignore any late text events
                                    // after submission has started.
                                    guard !model.isPosting else { return }
                                    model.text = newValue
                                }
                            ),
                            axis: .vertical
                        )
                        .lineLimit(1 ... 8)
                        .focused($isEditorFocused)
                        .submitLabel(.send)
                        .onSubmit { postIfPossible() }
                        .multilineTextAlignment(.leading)
                        // Match CommentRow's callout typography and the app's text scaling.
                        .scaledFont(.callout)
                        .foregroundStyle(.primary)
                        .tint(AppColors.appTintColor)
                        .padding(.top, Metrics.editorTopPadding)
                        .padding(.horizontal, Metrics.editorHorizontalPadding)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
                        .accessibilityLabel("Add a comment")
                        .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerEditor)
                    }

                    HStack(alignment: .center) {
                        cancelButton

                        Spacer(minLength: 8)

                        postButton
                    }
                    .padding(.horizontal, Metrics.cardHorizontalPadding)
                    .padding(.bottom, 2)
                }

                if let inlineError = model.inlineError {
                    Text(inlineError)
                        .scaledFont(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal, Metrics.cardHorizontalPadding)
                        .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerError)
                }
            }
            .padding(.top, model.replyUsername == nil ? Metrics.cardVerticalPadding : Metrics.cardTopPadding)
            .padding(.bottom, Metrics.cardVerticalPadding)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerExpanded)
            .onChange(of: model.presentation) { _, presentation in
                if presentation == .expanded {
                    // Focus on the next main-actor turn so the editor exists first.
                    Task { @MainActor in
                        await Task.yield()
                        isEditorFocused = true
                    }
                } else {
                    // External comment interactions collapse the model directly.
                    // Resign focus here as well so the keyboard follows that
                    // state change instead of leaving a detached editor focused.
                    isEditorFocused = false
                }
            }
            .onChange(of: isEditorFocused) { _, focused in
                // Losing focus collapses the composer while keeping the draft,
                // except while a submission is in flight.
                if !focused, model.isExpanded {
                    model.collapsePreservingDraft()
                }
            }
            .onAppear {
                if model.isExpanded {
                    isEditorFocused = true
                }
            }
        }
    }

    private var cancelButton: some View {
        Button {
            isEditorFocused = false
            model.cancel()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
        }
        .frame(width: 36, height: 36)
        .disabled(model.isPosting)
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(nil)
        .accessibilityLabel("Cancel")
        .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerCancel)
    }

    private var postButton: some View {
        Button(action: postIfPossible) {
            if model.isPosting {
                ProgressView()
                    .controlSize(.small)
                    .tint(nil)
                    .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerSpinner)
            } else {
                Image(systemName: "arrow.up")
                    .font(.system(size: 15, weight: .semibold))
            }
        }
        .frame(width: 36, height: 36)
        .disabled(!model.canPost)
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .accessibilityLabel("Post comment")
        .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerPost)
    }

    private func postIfPossible() {
        guard model.canPost else { return }
        // Transition synchronously so focus changes cannot collapse the
        // composer before the async submission task starts.
        model.beginPosting()
        isEditorFocused = true
        onSubmit()
    }
}
