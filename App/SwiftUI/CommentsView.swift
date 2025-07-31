//
//  CommentsView.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI
import SafariServices

struct CommentsView: View {
    let post: Post
    @EnvironmentObject private var navigationStore: NavigationStore
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var currentPost: Post
    @State private var commentsController = CommentsController()
    @State private var showingVoteError = false
    @State private var voteErrorMessage = ""
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var shareTitle: String = ""
    @State private var showingPostShareOptions = false
    @State private var refreshTrigger = false // Used to force SwiftUI updates
    @Environment(\.dismiss) private var dismiss

    init(post: Post) {
        self.post = post
        self._currentPost = State(initialValue: post)
    }

    // Computed property that filters visible comments
    private var visibleComments: [Comment] {
        _ = refreshTrigger // Force dependency on refreshTrigger
        return commentsController.visibleComments
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Post header with thumbnail and voting
                PostHeaderView(
                    post: currentPost,
                    onVote: { await handlePostVote() },
                    onLinkTap: { handleLinkTap() },
                    onShare: { showingPostShareOptions = true }
                )

                Divider()

                // Comments section
                if isLoading {
                    ProgressView("Loading comments...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if comments.isEmpty {
                    EmptyStateView("No comments yet")
                } else {
                    List(visibleComments, id: \.id) { comment in
                        CommentRowView(
                            comment: comment,
                            post: currentPost,
                            onToggle: { toggleCommentVisibility(comment) },
                            onVote: { await handleCommentVote(comment) },
                            onShare: { shareComment(comment) },
                            onCopy: { copyComment(comment) }
                        )
                        .contextMenu {
                            CommentContextMenu(
                                comment: comment,
                                onVote: { Task { await handleCommentVote(comment) } },
                                onShare: { shareComment(comment) },
                                onCopy: { copyComment(comment) }
                            )
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if UserDefaults.standard.swipeActionsEnabled {
                                Button {
                                    Task { await handleCommentVote(comment) }
                                } label: {
                                    Image(systemName: comment.upvoted ? "arrow.uturn.down" : "arrow.up")
                                }
                                .tint(comment.upvoted ? .secondary : Color(UIColor(named: "upvotedColor")!))
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            if UserDefaults.standard.swipeActionsEnabled {
                                Button {
                                    if let rootIndex = commentsController.indexOfVisibleRootComment(of: comment) {
                                        let rootComment = commentsController.visibleComments[rootIndex]
                                        toggleCommentVisibility(rootComment)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .tint(Color(UIColor(named: "appTintColor")!))
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if currentPost.url.host != nil {
                            Button("Article Link") {
                                sharePost(url: currentPost.url, title: currentPost.title)
                            }
                            Button("Hacker News Link") {
                                sharePost(url: currentPost.hackerNewsURL, title: currentPost.title)
                            }
                        } else {
                            Button("Hacker News Link") {
                                sharePost(url: currentPost.hackerNewsURL, title: currentPost.title)
                            }
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .refreshable {
                await loadComments()
            }
            .task {
                await loadComments()
            }
            .alert("Vote Error", isPresented: $showingVoteError) {
                Button("OK") { }
            } message: {
                Text(voteErrorMessage)
            }
        }
    }

    private func loadComments() async {
        isLoading = true

        do {
            // Load post with comments if not already loaded
            let postWithComments: Post
            if currentPost.comments == nil {
                postWithComments = try await HackersKit.shared.getPost(id: currentPost.id, includeAllComments: true)
                currentPost = postWithComments
            } else {
                postWithComments = currentPost
            }

            // Set comments
            let loadedComments = postWithComments.comments ?? []
            comments = loadedComments
            commentsController.comments = loadedComments
            currentPost.commentsCount = loadedComments.count
            refreshTrigger.toggle() // Ensure visibleComments updates
        } catch {
            print("Error loading comments: \(error)")
            // TODO: Show error state
        }

        isLoading = false
    }

    private func toggleCommentVisibility(_ comment: Comment) {
        withAnimation(.easeInOut(duration: 0.2)) {
            let _ = commentsController.toggleChildrenVisibility(of: comment)
            // Force SwiftUI to re-evaluate visibleComments
            refreshTrigger.toggle()
        }
    }

    @MainActor
    private func handlePostVote() async {
        let isUpvote = !currentPost.upvoted

        // Optimistically update UI
        currentPost.upvoted = isUpvote
        currentPost.score += isUpvote ? 1 : -1

        do {
            if isUpvote {
                try await HackersKit.shared.upvote(post: currentPost)
            } else {
                try await HackersKit.shared.unvote(post: currentPost)
            }
        } catch {
            // Revert optimistic update
            currentPost.upvoted = !isUpvote
            currentPost.score += isUpvote ? -1 : 1

            handleVoteError(error)
        }
    }

    @MainActor
    private func handleCommentVote(_ comment: Comment) async {
        let isUpvote = !comment.upvoted

        // Optimistically update UI
        comment.upvoted = isUpvote

        do {
            if isUpvote {
                try await HackersKit.shared.upvote(comment: comment, for: currentPost)
            } else {
                try await HackersKit.shared.unvote(comment: comment, for: currentPost)
            }
        } catch {
            // Revert optimistic update
            comment.upvoted = !isUpvote

            handleVoteError(error)
        }
    }

    private func handleVoteError(_ error: Error) {
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

    private func handleLinkTap() {
        guard !currentPost.url.absoluteString.starts(with: "item?id=") else { return }

        if let svc = SFSafariViewController.instance(for: currentPost.url) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(svc, animated: true) {
                    DraggableCommentsButton.attachTo(svc, with: currentPost)
                }
            }
        }
    }

    private func sharePost(url: URL, title: String) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            activityVC.setValue(title, forKey: "subject")

            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            rootVC.present(activityVC, animated: true)
        }
    }

    private func shareComment(_ comment: Comment) {
        sharePost(url: comment.hackerNewsURL, title: "Comment by \(comment.by)")
    }

    private func copyComment(_ comment: Comment) {
        UIPasteboard.general.string = comment.text.strippingHTML()
    }
}

struct PostHeaderView: View {
    let post: Post
    let onVote: () async -> Void
    let onLinkTap: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Thumbnail with proper loading
                ThumbnailView(url: UserDefaults.standard.showThumbnails ? post.url : nil)
                    .frame(width: 55, height: 55)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture {
                        onLinkTap()
                    }

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(post.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .onTapGesture {
                            onLinkTap()
                        }

                    // Metadata row
                    HStack(spacing: 3) {
                        Button {
                            Task { await onVote() }
                        } label: {
                            HStack(spacing: 0) {
                                Text("\(post.score)")
                                    .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                                Image(systemName: "arrow.up")
                                    .foregroundColor(post.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                                    .font(.system(size: 10))
                            }
                        }

                        Text("•")
                            .foregroundColor(.secondary)

                        HStack(spacing: 0) {
                            Text("\(post.commentsCount)")
                                .foregroundColor(.secondary)
                            Image(systemName: "message")
                                .foregroundColor(.secondary)
                                .font(.system(size: 10))
                        }

                        if let host = post.url.host, !post.url.absoluteString.starts(with: "item?id=") {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(host)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .font(.system(size: 13))
                }
            }

            if let text = post.text, !text.isEmpty {
                HTMLText(htmlString: text)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
        .padding()
    }
}

struct CommentRowView: View {
    let comment: Comment
    let post: Post
    let onToggle: () -> Void
    let onVote: () async -> Void
    let onShare: () -> Void
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.by)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(comment.by == post.by ? Color(UIColor(named: "appTintColor")!) : .primary)

                Text(comment.age)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                Spacer()

                if comment.upvoted {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Color(UIColor(named: "upvotedColor")!))
                        .font(.system(size: 14))
                }

                // Show visibility indicator
                if comment.visibility == .compact {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            // Only show full text if comment is visible
            if comment.visibility == .visible {
                HTMLText(htmlString: comment.text)
                    .foregroundColor(.primary)
            }
        }
        .padding(.leading, CGFloat(comment.level * 16))
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .opacity(comment.visibility == .hidden ? 0 : 1)
        .frame(height: comment.visibility == .hidden ? 0 : nil)
    }
}

struct CommentContextMenu: View {
    let comment: Comment
    let onVote: () -> Void
    let onShare: () -> Void
    let onCopy: () -> Void

    var body: some View {
        Group {
            Button {
                onVote()
            } label: {
                Label(comment.upvoted ? "Unvote" : "Upvote",
                      systemImage: comment.upvoted ? "arrow.uturn.down" : "arrow.up")
            }

            Button {
                onCopy()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }

            Divider()

            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}

// Simple HTML text view for now - can be enhanced later
struct HTMLText: View {
    let htmlString: String

    var body: some View {
        Text(htmlString.strippingHTML())
    }
}

extension String {
    func strippingHTML() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}

// ThumbnailView is imported from FeedView.swift

#Preview {
    let samplePost = Post(
        id: 1,
        url: URL(string: "https://ycombinator.com")!,
        title: "Sample Post Title with a longer title that might wrap to multiple lines",
        age: "2 hours ago",
        commentsCount: 42,
        by: "user123",
        score: 156,
        postType: .news,
        upvoted: false
    )

    CommentsView(post: samplePost)
        .environmentObject(NavigationStore())
}
