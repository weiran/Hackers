import DesignSystem
import Domain
import Shared
import SwiftUI

struct BrowserControlsView: View {
    let fallbackURL: URL
    let onDismiss: @MainActor () -> Void
    @ObservedObject var controller: BrowserController

    var body: some View {
        GlassEffectContainer(spacing: 18) {
            controlsLayout
        }
    }

    private var controlsLayout: some View {
        ZStack {
            navigationControlsGroup
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                closeButton
                    .padding(.leading, safeInsetPaddingLeft)

                Spacer()

                shareControlsGroup
                    .padding(.trailing, safeInsetPaddingRight)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
    }

    private var safeInsetPaddingLeft: CGFloat {
        let inset = PresentationContextProvider.shared.keyWindow?.safeAreaInsets.left ?? 0
        return max(inset, 12)
    }

    private var safeInsetPaddingRight: CGFloat {
        let inset = PresentationContextProvider.shared.keyWindow?.safeAreaInsets.right ?? 0
        return max(inset, 12)
    }

    private var navigationControlsGroup: some View {
        HStack(spacing: 18) {
            controlButton(systemName: "chevron.backward", isEnabled: controller.canGoBack) {
                controller.goBack()
            }

            controlButton(systemName: "chevron.forward", isEnabled: controller.canGoForward) {
                controller.goForward()
            }

            controlButton(systemName: controller.isLoading ? "xmark" : "arrow.clockwise") {
                if controller.isLoading {
                    controller.stopLoading()
                } else {
                    controller.reload()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .modifier(GlassCapsuleBackground())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    private var shareControlsGroup: some View {
        HStack(spacing: 18) {
            controlButton(systemName: "square.and.arrow.up") {
                Task { @MainActor in
                    let targetURL = controller.currentURL ?? fallbackURL
                    ContentSharePresenter.shared.shareURL(targetURL, title: controller.currentTitle)
                }
            }

            controlButton(systemName: "safari") {
                let targetURL = controller.currentURL ?? fallbackURL
                LinkOpener.openURL(targetURL)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .modifier(GlassCapsuleBackground())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    private var closeButton: some View {
        Button {
            Task { @MainActor in onDismiss() }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20, height: 20)
                .padding(10)
        }
        .foregroundStyle(.primary)
        .accessibilityLabel("Close")
        .modifier(GlassCircleBackground())
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }

    private func controlButton(
        systemName: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 20, height: 20)
        }
        .foregroundStyle(.primary)
        .opacity(isEnabled ? 1 : 0.35)
        .disabled(!isEnabled)
        .accessibilityLabel(controlLabel(for: systemName))
    }

    private func controlLabel(for systemName: String) -> String {
        switch systemName {
        case "chevron.backward":
            return "Back"
        case "chevron.forward":
            return "Forward"
        case "arrow.clockwise":
            return "Reload"
        case "xmark":
            return "Stop"
        case "square.and.arrow.up":
            return "Share"
        case "safari":
            return "Open in Safari"
        default:
            return "Button"
        }
    }
}

struct GlassCapsuleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.glassEffect(.regular.interactive(), in: .capsule)
    }
}

struct GlassCircleBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.glassEffect(.regular.interactive(), in: .circle)
    }
}

struct CollapsedPostHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme
    let post: Post
    let votingState: VotingState?
    let isLoading: Bool
    let onUpvote: () -> Void
    let onExpand: () -> Void
    private static let collapsedVerticalPadding: CGFloat = 2
    private static let collapsedHorizontalPadding: CGFloat = 20
    private static let collapsedThumbnailSize: CGFloat = 28

    var body: some View {
        HStack(spacing: 12) {
            ThumbnailView(url: post.url, isEnabled: true)
                .frame(width: Self.collapsedThumbnailSize, height: Self.collapsedThumbnailSize)
                .clipShape(.rect(cornerRadius: min(16, Self.collapsedThumbnailSize * 0.3)))

            Text(domainText)
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                upvoteButton
                commentsPill
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Self.collapsedHorizontalPadding)
        .padding(.vertical, Self.collapsedVerticalPadding)
        .contentShape(Rectangle())
        .onTapGesture(perform: onExpand)
    }

    private var domainText: String {
        let host = post.url.host ?? "Hackers"
        let trimmed = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        return trimmed.uppercased()
    }

    private var commentsPill: some View {
        let style = AppColors.PillStyle.comments
        let textColor = AppColors.pillForeground(for: style, colorScheme: colorScheme)
        let backgroundColor = AppColors.pillBackground(for: style, colorScheme: colorScheme)

        return PostPillView(
            iconName: "message",
            text: "\(post.commentsCount)",
            textColor: textColor,
            backgroundColor: backgroundColor,
            numericValue: post.commentsCount
        )
        .accessibilityLabel("\(post.commentsCount) comments")
    }

    private var upvoteButton: some View {
        let isUpvoted = votingState?.isUpvoted ?? post.upvoted
        let score = votingState?.score ?? post.score
        let canVote = votingState?.canVote ?? (post.voteLinks?.upvote != nil)
        let canUnvote = votingState?.canUnvote ?? (post.voteLinks?.unvote != nil)
        let isVoting = votingState?.isVoting ?? isLoading
        let canInteract = ((canVote && !isUpvoted) || (canUnvote && isUpvoted)) && !isVoting
        let iconName = isUpvoted ? "arrow.up.circle.fill" : "arrow.up"
        let style = AppColors.PillStyle.upvote(isActive: isUpvoted)
        let textColor = AppColors.pillForeground(for: style, colorScheme: colorScheme)
        let backgroundColor = AppColors.pillBackground(for: style, colorScheme: colorScheme)

        return Button(action: onUpvote) {
            PostPillView(
                iconName: iconName,
                text: "\(score)",
                textColor: textColor,
                backgroundColor: backgroundColor,
                isLoading: isVoting,
                numericValue: score
            )
        }
        .buttonStyle(.plain)
        .disabled(!canInteract)
        .opacity(canInteract ? 1 : 0.55)
        .accessibilityLabel(isUpvoted ? "Upvoted" : "Upvote")
    }
}

struct CollapsedPostHeaderLoadingView: View {
    var body: some View {
        HStack(spacing: 12) {
            Text("Loading...")
                .scaledFont(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Capsule()
                .fill(.secondary.opacity(0.2))
                .frame(width: 52, height: 22)
            Capsule()
                .fill(.secondary.opacity(0.2))
                .frame(width: 52, height: 22)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 2)
    }
}

enum ControlsHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

enum CollapsedHeaderHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
