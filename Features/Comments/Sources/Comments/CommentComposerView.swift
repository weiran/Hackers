//
//  CommentComposerView.swift
//  Comments
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
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
        static let actionRowHeight: CGFloat = 36
        // Match the editor's visible horizontal inset to the card's 6pt inset
        // plus the editor's 8pt top inset.
        static let editorHorizontalPadding: CGFloat = cardVerticalPadding + editorTopPadding
        // The collapsed pill reproduces the original 48pt footprint. The
        // vertical-axis TextField adds ~2pt of intrinsic chrome, hence 46.
        static let collapsedEditorMinHeight: CGFloat = 46
        static let expandedEditorMinHeight: CGFloat = 40
        // Space between the editor and the action row inside the expanded card.
        static let expandedEditorBottomInset: CGFloat = 4
    }

    @Bindable var model: CommentComposerModel
    let onSubmit: () -> Void

    @FocusState private var isEditorFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        composerSurface
    }

    /// One persistent glass surface hosts one persistent content stack: no
    /// subtree ever structurally replaces another, every dimension tween is a
    /// plain number (paddings, the action row height, opacities). That keeps
    /// the Liquid Glass capsule tracking a smoothly interpolated frame so
    /// expanding stretches the pill into the editor card instead of snapping.
    private var composerSurface: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let username = model.replyUsername {
                Text("Replying to \(username)")
                    .scaledFont(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Metrics.editorHorizontalPadding)
                    .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerReplyLabel)
            }

            editorBlock

            actionRow
                // Tweaking the row's height numerically lets the glass surface
                // ride the same animation instead of jumping to a new size.
                .frame(height: model.isExpanded ? Metrics.actionRowHeight : 0, alignment: .center)
                .padding(.bottom, model.isExpanded ? 2 : 0)
                .opacity(model.isExpanded ? 1 : 0)
                .clipped()
                .allowsHitTesting(model.isExpanded)

            if let inlineError = model.inlineError {
                Text(inlineError)
                    .scaledFont(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, Metrics.cardHorizontalPadding)
                    .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerError)
            }
        }
        // The expanded card restores the original surface breathing room on
        // top of the content paddings; collapsed keeps the bare 48pt pill.
        .padding(
            .top,
            model.isExpanded
                ? (model.replyUsername == nil ? Metrics.cardVerticalPadding : Metrics.cardTopPadding)
                : 0
        )
        .padding(.bottom, model.isExpanded ? Metrics.cardVerticalPadding : 0)
        .animation(ComposerMotion.animation(isReducedMotion: reduceMotion), value: model.isExpanded)
        // Without this the glass renderer blends/cross-fades the surface
        // across state changes instead of visibly reshaping it; .identity
        // makes the capsule track the interpolated frame directly.
        .glassEffectTransition(.identity)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
        .contentShape(.rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerExpanded)
        .overlay {
            // While collapsed the whole card is the expand affordance; an
            // invisible labelled button on top keeps the pill's original
            // accessible name and tap target without affecting layout.
            if !model.isExpanded {
                Button {
                    expandFromCollapsed()
                } label: {
                    Color.clear
                        .contentShape(Rectangle())
                        .accessibilityLabel(
                            model.draftPreview ?? "Add a comment…"
                        )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerCollapsed)
                .transition(.opacity)
            }
        }
        .onChange(of: model.presentation) { _, presentation in
            if presentation == .expanded {
                // Focus lands with the expansion so the keyboard and the
                // capsule growth travel together.
                Task { @MainActor in
                    await Task.yield()
                    guard model.isExpanded else { return }
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
                withAnimation(ComposerMotion.animation(isReducedMotion: reduceMotion)) {
                    model.collapsePreservingDraft()
                }
            }
        }
        .onAppear {
            if model.isExpanded {
                isEditorFocused = true
            }
        }
    }

    private var editorBlock: some View {
        // Vertically top-anchored while expanded (multi-line growth) and
        // vertically centered in the pill while collapsed; the editor's
        // top inset tweens numerically with the state so neither the field
        // nor its placeholder jumps between states.
        ZStack(alignment: model.isExpanded ? .topLeading : .leading) {
            if model.text.isEmpty {
                Text("Add a comment…")
                    .scaledFont(.callout)
                    .foregroundStyle(Color.primary.opacity(0.72))
                    .padding(.top, model.isExpanded ? Metrics.editorTopPadding : 0)
                    .padding(.horizontal, Metrics.editorHorizontalPadding)
                    .allowsHitTesting(false)
            }

            TextField(
                "",
                text: Binding(
                    get: { model.text },
                    set: { newValue in
                        // The editor is disabled while the post is in
                        // flight; ignore any late text events too.
                        guard !model.isPosting else { return }
                        model.text = newValue
                    }
                ),
                axis: .vertical
            )
            .lineLimit(model.isExpanded ? 1 ... 8 : 1 ... 1)
            .focused($isEditorFocused)
            .submitLabel(.send)
            .onSubmit { postIfPossible() }
            .multilineTextAlignment(.leading)
            // Match CommentRow's callout typography and the app's text scaling.
            .scaledFont(.callout)
            .foregroundStyle(.primary)
            .tint(AppColors.appTintColor)
            .padding(.top, model.isExpanded ? Metrics.editorTopPadding : 0)
            .padding(.bottom, model.isExpanded ? Metrics.expandedEditorBottomInset : 0)
            .padding(.horizontal, Metrics.editorHorizontalPadding)
            .frame(maxWidth: .infinity, minHeight: model.isExpanded
                ? Metrics.expandedEditorMinHeight
                : Metrics.collapsedEditorMinHeight,
                alignment: model.isExpanded ? .topLeading : .leading)
            // Locks the field while a submission is in flight; the model's
            // collapse guard keeps a focus loss here from closing the card.
            .disabled(model.isPosting)
            .accessibilityLabel("Add a comment")
            .accessibilityIdentifier(AccessibilityIdentifier.Comments.composerEditor)
        }
    }

    private var actionRow: some View {
        HStack(alignment: .center) {
            cancelButton

            Spacer(minLength: 8)

            postButton
        }
        .padding(.horizontal, Metrics.cardHorizontalPadding)
    }

    private var cancelButton: some View {
        Button {
            isEditorFocused = false
            withAnimation(ComposerMotion.animation(isReducedMotion: reduceMotion)) {
                model.cancel()
            }
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
        // Resign focus before the in-flight disable commits. Re-asserting
        // focus here instead leaves a pending focus request that lands on
        // the disabled editor and wedges the keyboard: it survives the
        // collapse after a successful post and never resigns.
        isEditorFocused = false
        onSubmit()
    }

    /// Tapped-pill expansion: the growth spring and the keyboard slide run
    /// together in one motion.
    private func expandFromCollapsed() {
        withAnimation(ComposerMotion.animation(isReducedMotion: reduceMotion)) {
            model.expand()
        }
        isEditorFocused = true
    }
}
