//
//  FeedView.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI
import UIKit
import SafariServices

struct FeedView: View {
    @StateObject private var viewModel = SwiftUIFeedViewModel()
    @EnvironmentObject private var navigationStore: NavigationStore
    @State private var selectedPostType: PostType = .news
    @State private var showingVoteError = false
    @State private var voteErrorMessage = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                            ForEach(viewModel.posts, id: \.id) { post in
                                PostRowView(
                                    post: post,
                                    navigationStore: navigationStore,
                                    onVote: { post in
                                        Task {
                                            await handleVote(post: post)
                                        }
                                    },
                                    onLinkTap: { post in
                                        handleLinkTap(post: post)
                                    },
                                    onCommentsTap: { post in
                                        // This callback is no longer needed since we use NavigationLink
                                    }
                                )
                                .onAppear {
                                    // Load next page when near end
                                    if post == viewModel.posts.last {
                                        Task {
                                            await viewModel.loadNextPage()
                                        }
                                    }
                                }
                                .contextMenu {
                                    PostContextMenu(
                                        post: post,
                                        onVote: { post in
                                            Task {
                                                await handleVote(post: post)
                                            }
                                        },
                                        onOpenLink: { post in
                                            handleLinkTap(post: post)
                                        },
                                        onShare: { post in
                                            sharePost(post)
                                        }
                                    )
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    if UserDefaults.standard.swipeActionsEnabled {
                                        Button {
                                            Task {
                                                await handleVote(post: post)
                                            }
                                        } label: {
                                            Image(systemName: post.upvoted ? "arrow.uturn.down" : "arrow.up")
                                        }
                                        .tint(post.upvoted ? .secondary : Color(UIColor(named: "upvotedColor")!))
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            await viewModel.loadFeed()
                        }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Menu {
                        ForEach(PostType.allCases, id: \.self) { postType in
                            Button {
                                selectedPostType = postType
                                navigationStore.selectPostType(postType)
                                viewModel.postType = postType
                                Task {
                                    await viewModel.loadFeed()
                                }
                            } label: {
                                HStack {
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
                            Text(selectedPostType.displayName)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        navigationStore.showLogin()
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigationStore.showSettings()
                    } label: {
                        Image(systemName: "gear")
                    }
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
        }
    }

    @MainActor
    private func handleVote(post: Post) async {
        let isUpvote = !post.upvoted

        // Optimistically update UI
        post.upvoted = isUpvote
        post.score += isUpvote ? 1 : -1

        do {
            try await viewModel.vote(on: post, upvote: isUpvote)
        } catch {
            // Revert optimistic update
            post.upvoted = !isUpvote
            post.score += isUpvote ? -1 : 1

            if let hackersError = error as? HackersKitError {
                switch hackersError {
                case .unauthenticated:
                    navigationStore.showLogin()
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

    private func handleLinkTap(post: Post) {
        guard !post.url.absoluteString.starts(with: "item?id=") else {
            navigationStore.showPost(post)
            return
        }

        if let svc = SFSafariViewController.instance(for: post.url) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(svc, animated: true) {
                    DraggableCommentsButton.attachTo(svc, with: post)
                }
            }
        }
    }

    private func sharePost(_ post: Post) {
        let url = post.url.host != nil ? post.url : post.hackerNewsURL

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            rootVC.present(activityVC, animated: true)
        }
    }
}

struct PostRowView: View {
    let post: Post
    let onVote: ((Post) -> Void)?
    let onLinkTap: ((Post) -> Void)?
    let onCommentsTap: ((Post) -> Void)?
    let navigationStore: NavigationStore

    init(post: Post, navigationStore: NavigationStore, onVote: ((Post) -> Void)? = nil, onLinkTap: ((Post) -> Void)? = nil, onCommentsTap: ((Post) -> Void)? = nil) {
        self.post = post
        self.navigationStore = navigationStore
        self.onVote = onVote
        self.onLinkTap = onLinkTap
        self.onCommentsTap = onCommentsTap
    }

    var body: some View {
        NavigationLink(destination: CommentsView(post: post).environmentObject(navigationStore)) {
            HStack(spacing: 12) {
                // Thumbnail with proper loading
                ThumbnailView(url: UserDefaults.standard.showThumbnails ? post.url : nil)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(post.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Metadata row
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Text("\(post.score)")
                                .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                            Image(systemName: "arrow.up")
                                .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                                .font(.system(size: 10))
                        }

                        Text("•")
                            .foregroundColor(.secondary)

                        HStack(spacing: 2) {
                            Text("\(post.commentsCount)")
                                .foregroundColor(.secondary)
                            Image(systemName: "message")
                                .foregroundColor(.secondary)
                                .font(.system(size: 10))
                        }

                        Text("•")
                            .foregroundColor(.secondary)

                        if let host = post.url.host, !post.url.absoluteString.starts(with: "item?id=") {
                            Text(host)
                                .foregroundColor(.secondary)
                        } else {
                            Text("self")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.system(size: 13))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
    }
}

struct PostContextMenu: View {
    let post: Post
    let onVote: (Post) -> Void
    let onOpenLink: (Post) -> Void
    let onShare: (Post) -> Void

    var body: some View {
        Group {
            Button {
                onVote(post)
            } label: {
                Label(post.upvoted ? "Unvote" : "Upvote",
                      systemImage: post.upvoted ? "arrow.uturn.down" : "arrow.up")
            }

            Divider()

            if !post.url.absoluteString.starts(with: "item?id=") {
                Button {
                    onOpenLink(post)
                } label: {
                    Label("Open Link", systemImage: "safari")
                }
            }

            Button {
                onShare(post)
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}

// SwiftUI-compatible FeedViewModel
class SwiftUIFeedViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false

    var postType: PostType = .news {
        didSet {
            if postType != oldValue {
                feedViewModel.postType = postType
            }
        }
    }

    private let feedViewModel = FeedViewModel()

    @MainActor
    func loadFeed() async {
        guard !isLoading else { return }

        isLoading = true
        feedViewModel.postType = postType
        feedViewModel.reset()

        do {
            try await feedViewModel.fetchFeed()
            posts = feedViewModel.posts
        } catch {
            print("Error loading feed: \(error)")
            // TODO: Add error state handling
        }

        isLoading = false
    }

    @MainActor
    func loadNextPage() async {
        guard !isLoading && !isLoadingMore && !feedViewModel.isFetching else { return }

        isLoadingMore = true

        do {
            try await feedViewModel.fetchFeed(fetchNextPage: true)
            posts = feedViewModel.posts
        } catch {
            print("Error loading next page: \(error)")
        }

        isLoadingMore = false
    }

    func vote(on post: Post, upvote: Bool) async throws {
        try await feedViewModel.vote(on: post, upvote: upvote)
    }
}

struct ThumbnailView: View {
    let url: URL?

    private func thumbnailURL(for url: URL) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "hackers-thumbnails.weiranzhang.com"
        components.path = "/api/FetchThumbnail"
        let urlString = url.absoluteString
        components.queryItems = [URLQueryItem(name: "url", value: urlString)]
        return components.url
    }

    private var placeholderImage: some View {
        Image(systemName: "safari")
            .font(.title2)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.secondary.opacity(0.1))
    }

    var body: some View {
        if let url = url, let thumbnailURL = thumbnailURL(for: url) {
            AsyncImage(url: thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholderImage
            }
        } else {
            placeholderImage
        }
    }
}

extension PostType {
    var displayName: String {
        switch self {
        case .news: return "Top"
        case .ask: return "Ask"
        case .show: return "Show"
        case .jobs: return "Jobs"
        case .newest: return "New"
        case .best: return "Best"
        case .active: return "Active"
        }
    }
}

#Preview {
    FeedView()
        .environmentObject(NavigationStore())
}
