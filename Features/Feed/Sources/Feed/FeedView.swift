import SwiftUI
import Domain
import Shared
import DesignSystem

public struct CleanFeedView<NavigationStore: NavigationStoreProtocol>: View {
    @State private var viewModel: FeedViewModel
    @State private var selectedPostType: Domain.PostType = .news
    @State private var selectedPostId: Int?
    @State private var showingVoteError = false
    @State private var voteErrorMessage = ""
    @State private var showingAuthenticationDialog = false
    @EnvironmentObject private var navigationStore: NavigationStore

    let isSidebar: Bool
    let showThumbnails: Bool
    let swipeActionsEnabled: Bool

    public init(
        viewModel: FeedViewModel = FeedViewModel(),
        isSidebar: Bool = false,
        showThumbnails: Bool = true,
        swipeActionsEnabled: Bool = false
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.isSidebar = isSidebar
        self.showThumbnails = showThumbnails
        self.swipeActionsEnabled = swipeActionsEnabled
    }

    private var selectionBinding: Binding<Int?> {
        if isSidebar {
            Binding(
                get: { selectedPostId },
                set: { newPostId in
                    if let postId = newPostId,
                       let selectedPost = viewModel.posts.first(where: { $0.id == postId }) {
                        selectedPostId = postId
                        navigationStore.showPost(selectedPost)
                    }
                }
            )
        } else {
            .constant(nil)
        }
    }

    public var body: some View {
        NavigationStack {
            contentView
                .navigationBarTitleDisplayMode(.inline)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                toolbarMenu
            }
        }
        .task { @Sendable in
            await viewModel.loadFeed()
        }
        .alert("Vote Error", isPresented: $showingVoteError) {
            Button("OK") { }
        } message: {
            Text(voteErrorMessage)
        }
        .sheet(isPresented: $showingAuthenticationDialog) {
            Text("Please log in to vote")
                .onAppear {
                    navigationStore.showLogin()
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading && viewModel.posts.isEmpty {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(selection: selectionBinding) {
                ForEach(viewModel.posts, id: \.id) { post in
                    postRow(for: post)
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.refreshFeed()
            }
        }
    }

    @ViewBuilder
    private func postRow(for post: Domain.Post) -> some View {
        PostRowView(
            post: post,
            showThumbnails: showThumbnails,
            onVote: {
                Task { await handleVote(post: post) }
            },
            onLinkTap: { handleLinkTap(post: post) },
            onCommentsTap: { navigationStore.showPost(post) }
        )
        .if(isSidebar) { view in
            view.tag(post.id)
        }
        .onAppear {
            if post == viewModel.posts.last {
                Task {
                    await viewModel.loadNextPage()
                }
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if swipeActionsEnabled {
                Button {
                    Task { await handleVote(post: post) }
                } label: {
                    Image(systemName: post.upvoted ? "arrow.uturn.down" : "arrow.up")
                }
                .tint(post.upvoted ? .secondary : AppColors.upvotedColor)
            }
        }
        .contextMenu {
            PostContextMenu(
                post: post,
                onVote: { Task { await handleVote(post: post) } },
                onOpenLink: { handleLinkTap(post: post) },
                onShare: { ShareService.shared.sharePost(post) }
            )
        }
    }

    @ViewBuilder
    private var toolbarMenu: some View {
        Menu {
            ForEach(Domain.PostType.allCases, id: \.self) { postType in
                Button {
                    selectedPostType = postType
                    Task {
                        await viewModel.changePostType(postType)
                    }
                } label: {
                    HStack {
                        Image(systemName: postType.iconName)
                        Text(postType.displayName)
                        if postType == selectedPostType {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedPostType.iconName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(selectedPostType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @MainActor
    private func handleVote(post: Domain.Post) async {
        let isUpvote = !post.upvoted

        do {
            try await viewModel.vote(on: post, upvote: isUpvote)
        } catch {
            if let hackersError = error as? HackersKitError {
                switch hackersError {
                case .unauthenticated:
                    showingAuthenticationDialog = true
                default:
                    voteErrorMessage = "Failed to vote. Please try again."
                    showingVoteError = true
                }
            } else {
                voteErrorMessage = "Failed to vote. Please try again."
                showingVoteError = true
            }
        }
    }

    private func handleLinkTap(post: Domain.Post) {
        guard !post.url.absoluteString.starts(with: HackerNewsConstants.itemPrefix) else {
            navigationStore.showPost(post)
            return
        }

        LinkOpener.openURL(post.url, with: nil, showCommentsButton: false)
    }
}

struct PostRowView: View {
    let post: Domain.Post
    let showThumbnails: Bool
    let onVote: (() -> Void)?
    let onLinkTap: (() -> Void)?
    let onCommentsTap: (() -> Void)?

    init(post: Domain.Post,
         showThumbnails: Bool = true,
         onVote: (() -> Void)? = nil,
         onLinkTap: (() -> Void)? = nil,
         onCommentsTap: (() -> Void)? = nil) {
        self.post = post
        self.showThumbnails = showThumbnails
        self.onVote = onVote
        self.onLinkTap = onLinkTap
        self.onCommentsTap = onCommentsTap
    }

    var body: some View {
        PostDisplayView(
            post: post,
            showPostText: false,
            showThumbnails: showThumbnails,
            onThumbnailTap: onLinkTap
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onCommentsTap?()
        }
    }
}

extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
