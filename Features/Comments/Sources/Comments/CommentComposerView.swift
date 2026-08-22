//
//  CommentComposerView.swift
//  Comments
//
//  The shared bottom composer for top-level comments and replies.
//

import Domain
import Shared
import SwiftUI

struct CommentComposerView: View {
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
                    .foregroundStyle(model.draftPreview == nil ? .secondary : .primary)
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
        VStack(alignment: .leading, spacing: 8) {
            if let username = model.replyUsername {
                Text("Replying to \(username)")
                    .scaledFont(.footnote)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerReplyLabel)
            }

            TextField(
                "Add a comment…",
                text: Binding(
                    get: { model.text },
                    set: { model.text = $0 }
                ),
                axis: .vertical
            )
            .lineLimit(2 ... 8)
            .focused($isEditorFocused)
            .disabled(model.isPosting)
            .submitLabel(.send)
            .onSubmit { postIfPossible() }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.fill.tertiary, in: .rect(cornerRadius: 14))
            .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerEditor)

            if let inlineError = model.inlineError {
                Text(inlineError)
                    .scaledFont(.footnote)
                    .foregroundStyle(.red)
                    .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerError)
            }

            HStack {
                Button("Cancel") {
                    isEditorFocused = false
                    model.cancel()
                }
                .disabled(model.isPosting)
                .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerCancel)

                Spacer()

                postButton
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerExpanded)
        .onChange(of: model.presentation) { _, presentation in
            if presentation == .expanded {
                // Focus on the next main-actor turn so the editor exists first.
                Task { @MainActor in
                    await Task.yield()
                    isEditorFocused = true
                }
            }
        }
        .onChange(of: isEditorFocused) { _, focused in
            // Losing focus collapses the composer while keeping the draft,
            // except mid-posting when the editor is disabled anyway.
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

    private var postButton: some View {
        Button(action: postIfPossible) {
            if model.isPosting {
                ProgressView()
                    .controlSize(.small)
                    .frame(minWidth: postLabelWidth)
                    .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerSpinner)
            } else {
                Text("Post")
                    .frame(minWidth: postLabelWidth)
            }
        }
        .disabled(!model.canPost)
        .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerPost)
    }

    private var postLabelWidth: CGFloat {
        44
    }

    private func postIfPossible() {
        guard model.canPost else { return }
        onSubmit()
    }
}
