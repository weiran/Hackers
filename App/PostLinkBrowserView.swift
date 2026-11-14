import Comments
import Domain
import Shared
import SwiftUI
import UIKit

@MainActor
private struct NavigationBackSwipeRestorer: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> ProbeViewController {
        let viewController = ProbeViewController()
        viewController.view.backgroundColor = .clear
        viewController.view.isUserInteractionEnabled = false
        viewController.onLifecycle = { [weak coordinator = context.coordinator] viewController in
            coordinator?.installIfPossible(from: viewController)
        }
        return viewController
    }

    func updateUIViewController(_ viewController: ProbeViewController, context: Context) {
        viewController.onLifecycle = { [weak coordinator = context.coordinator] viewController in
            coordinator?.installIfPossible(from: viewController)
        }
        context.coordinator.installIfPossible(from: viewController)

        let coordinator = context.coordinator
        Task { @MainActor [weak viewController, weak coordinator] in
            guard let viewController else { return }
            coordinator?.installIfPossible(from: viewController)
        }
    }

    static func dismantleUIViewController(_ viewController: ProbeViewController, coordinator: Coordinator) {
        coordinator.restore()
        viewController.onLifecycle = nil
    }

    final class ProbeViewController: UIViewController {
        var onLifecycle: ((ProbeViewController) -> Void)?

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            onLifecycle?(self)
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            onLifecycle?(self)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            onLifecycle?(self)
        }
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var navigationController: UINavigationController?
        private weak var edgeGesture: UIGestureRecognizer?
        private weak var contentGesture: UIGestureRecognizer?
        private weak var originalEdgeDelegate: UIGestureRecognizerDelegate?
        private weak var originalContentDelegate: UIGestureRecognizerDelegate?

        func installIfPossible(from viewController: UIViewController) {
            guard let navigationController = viewController.nearestNavigationController else { return }
            install(on: navigationController)
        }

        private func install(on navigationController: UINavigationController) {
            self.navigationController = navigationController

            if let gesture = navigationController.interactivePopGestureRecognizer {
                if edgeGesture !== gesture {
                    edgeGesture = gesture
                    originalEdgeDelegate = gesture.delegate
                } else if gesture.delegate !== self {
                    originalEdgeDelegate = gesture.delegate
                }
                gesture.isEnabled = true
                gesture.delegate = self
            }

            if #available(iOS 26.0, *),
               let gesture = navigationController.interactiveContentPopGestureRecognizer {
                if contentGesture !== gesture {
                    contentGesture = gesture
                    originalContentDelegate = gesture.delegate
                } else if gesture.delegate !== self {
                    originalContentDelegate = gesture.delegate
                }
                gesture.isEnabled = true
                gesture.delegate = self
            }
        }

        func restore() {
            if edgeGesture?.delegate === self {
                edgeGesture?.delegate = originalEdgeDelegate
            }
            if #available(iOS 26.0, *),
               contentGesture?.delegate === self {
                contentGesture?.delegate = originalContentDelegate
            }
            edgeGesture = nil
            contentGesture = nil
            navigationController = nil
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard isManagedPopGesture(gestureRecognizer) else { return true }
            guard let navigationController else { return false }
            guard navigationController.viewControllers.count > 1 else { return false }
            guard navigationController.transitionCoordinator == nil else { return false }

            if #available(iOS 26.0, *), gestureRecognizer === contentGesture {
                let location = gestureRecognizer.location(in: navigationController.view)
                return location.x <= systemPopStartMaxX(in: navigationController)
            }

            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard isManagedPopGesture(gestureRecognizer) else { return true }
            guard let navigationController else { return false }

            if #available(iOS 26.0, *), gestureRecognizer === contentGesture {
                let location = touch.location(in: navigationController.view)
                return location.x <= systemPopStartMaxX(in: navigationController)
            }

            return true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            isManagedPopGesture(gestureRecognizer) || isManagedPopGesture(otherGestureRecognizer)
        }

        private func isManagedPopGesture(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer === edgeGesture {
                return true
            }
            if #available(iOS 26.0, *), gestureRecognizer === contentGesture {
                return true
            }
            return false
        }

        private func systemPopStartMaxX(in navigationController: UINavigationController) -> CGFloat {
            navigationController.view.safeAreaInsets.left + 32
        }
    }
}

private extension UIViewController {
    var nearestNavigationController: UINavigationController? {
        if let navigationController {
            return navigationController
        }

        var current = parent
        while let viewController = current {
            if let navigationController = viewController as? UINavigationController {
                return navigationController
            }
            if let navigationController = viewController.navigationController {
                return navigationController
            }
            current = viewController.parent
        }

        return nil
    }
}

struct PostLinkBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    let post: Post
    let presentation: PostLinkPresentation
    let onClose: (@MainActor () -> Void)?
    @State private var showingCommentsPane = false
    @State private var collapsedCommentsHeight = PostCommentsSheet.initialCollapsedHeight
    @State private var browserObscuredBottomInset = PostCommentsSheet.collapsedBrowserBottomInset
    @State private var commentsAreExpanded: Bool
    @StateObject private var browserController: BrowserController
    private let commentsViewModel: CommentsViewModel

    init(
        post: Post,
        presentation: PostLinkPresentation,
        controller: BrowserController? = nil,
        commentsViewModel: CommentsViewModel? = nil,
        onClose: (@MainActor () -> Void)? = nil
    ) {
        self.post = post
        self.presentation = presentation
        self.onClose = onClose
        _showingCommentsPane = State(initialValue: presentation == .expandedComments)
        _commentsAreExpanded = State(initialValue: presentation == .expandedComments)
        _browserController = StateObject(wrappedValue: controller ?? BrowserController(
            mediaPlaybackSuspended: presentation == .expandedComments
        ))
        self.commentsViewModel = commentsViewModel ?? CommentsViewModel(post: post)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            EmbeddedWebView(
                url: post.url,
                onDismiss: close,
                showsCloseButton: false,
                showsToolbar: false,
                bottomWebViewInset: browserBottomInset,
                obscuredBottomInset: browserObscuredBottomInset,
                controller: browserController
            )

            if showingCommentsPane {
                PostCommentsSheet(
                    post: post,
                    controller: browserController,
                    viewModel: commentsViewModel,
                    isExpanded: $commentsAreExpanded,
                    initialPresentation: presentation,
                    onDismiss: close,
                    onCollapsedHeightChange: { collapsedCommentsHeight = $0 },
                    onBrowserObscuredBottomInsetChange: { browserObscuredBottomInset = $0 },
                    onMediaPlaybackSuspensionChange: { isSuspended in
                        browserController.setMediaPlaybackSuspended(isSuspended)
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityIdentifier.Browser.view)
        .modifier(AdaptiveBrowserControls())
        .toolbar {
            if #available(iOS 27.1, *) {
                ToolbarItem(id: "browser.commentsToggle", placement: .topBarPinnedTrailing) {
                    Button(
                        commentsAreExpanded ? "Show Article" : "Show Comments",
                        systemImage: commentsAreExpanded ? "doc.text" : "message"
                    ) {
                        commentsAreExpanded.toggle()
                    }
                }
                .axisBehavior(.verticalPreferred)
                if !commentsAreExpanded {
                    ToolbarItem(id: "browser.share", placement: .primaryAction) {
                        Button("Share", systemImage: "square.and.arrow.up") {
                            ContentSharePresenter.shared.shareURL(
                                browserController.currentURL ?? post.url,
                                title: browserController.currentTitle
                            )
                        }
                    }
                    .visibilityPriority(.high)
                    .axisBehavior(.verticalPreferred)
                    ToolbarItem(id: "browser.reload", placement: .primaryAction) {
                        Button(
                            browserController.isLoading ? "Stop" : "Reload",
                            systemImage: browserController.isLoading ? "xmark" : "arrow.clockwise"
                        ) {
                            if browserController.isLoading {
                                browserController.stopLoading()
                            } else {
                                browserController.reload()
                            }
                        }
                    }
                    .visibilityPriority(.low)
                    .axisBehavior(.verticalPreferred)
                    ToolbarOverflowMenu {
                        Button(
                            "Previous Page",
                            systemImage: "arrow.backward",
                            action: browserController.goBack
                        )
                        .disabled(!browserController.canGoBack)
                        Button(
                            "Next Page",
                            systemImage: "arrow.forward",
                            action: browserController.goForward
                        )
                        .disabled(!browserController.canGoForward)
                        Button("Open in Safari", systemImage: "safari") {
                            LinkOpener.openInSystemBrowser(browserController.currentURL ?? post.url)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background {
            NavigationBackSwipeRestorer()
                .frame(width: 0, height: 0)
        }
        .task {
            guard !showingCommentsPane else { return }
            withAnimation(WebViewAnimations.panel) {
                showingCommentsPane = true
            }
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private var browserBottomInset: CGFloat {
        max(collapsedCommentsHeight - PostCommentsSheet.collapsedTopCornerRadius, 0)
    }
}
