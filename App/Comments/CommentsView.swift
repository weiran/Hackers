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
    @State private var showingAuthenticationDialog = false
    @State private var showingShareSheet = false
    @State private var shareURL: URL?
    @State private var shareTitle: String = ""
    @State private var showingPostShareOptions = false
    @State private var refreshTrigger = false // Used to force SwiftUI updates
    @State private var showTitle = false
    @State private var headerHeight: CGFloat = 0
    @State private var visibleCommentPositions: [Int: CGRect] = [:]
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
                // Comments section
                if isLoading {
                    ProgressView("Loading comments...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if comments.isEmpty {
                    EmptyStateView("No comments yet")
                } else {
                    ScrollViewReader { proxy in
                        List {
                            PostHeaderView(
                                post: currentPost,
                                onVote: { await handlePostVote() },
                                onLinkTap: { handleLinkTap() },
                                onShare: { showingPostShareOptions = true }
                            )
                            .id("header")
                            .background(GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ViewOffsetKey.self,
                                    value: geometry.frame(in: .global).minY
                                )
                            })
                            .onPreferenceChange(ViewOffsetKey.self) { offset in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    // Show title when header scrolls above navigation bar (approximately)
                                    showTitle = offset < 50
                                }
                            }

                            ForEach(visibleComments, id: \.id) { comment in
                                CommentRowView(
                                    comment: comment,
                                    post: currentPost,
                                    onToggle: { 
                                        toggleCommentVisibility(comment) { id in
                                            proxy.scrollTo(id, anchor: .top)
                                        }
                                    },
                                    onVote: { await handleCommentVote(comment) },
                                    onShare: { shareComment(comment) },
                                    onCopy: { copyComment(comment) }
                                )
                                .id("comment-\(comment.id)")
                                .background(GeometryReader { geometry in
                                    Color.clear.preference(
                                        key: CommentPositionKey.self,
                                        value: CommentPosition(id: comment.id, frame: geometry.frame(in: .global))
                                    )
                                })
                                .onPreferenceChange(CommentPositionKey.self) { position in
                                    if let position = position {
                                        visibleCommentPositions[position.id] = position.frame
                                    }
                                }
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
                                                toggleCommentVisibility(rootComment) { id in
                                                    proxy.scrollTo(id, anchor: .top)
                                                }
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle")
                                        }
                                    }
                                }
                                .authenticationDialog(isPresented: $showingAuthenticationDialog) {
                                    navigationStore.showLogin()
                                }
                            }
                            .listRowInsets(EdgeInsets()) // Remove default insets
                            .listRowBackground(Color.clear) // Remove background
                            .listRowSeparator(.hidden) // Hide separators
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        ThumbnailView(url: UserDefaults.standard.showThumbnails ? post.url : nil)
                            .frame(width: 33, height: 33)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text(currentPost.title)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .onTapGesture {
                        handleLinkTap()
                    }
                    .opacity(showTitle ? 1.0 : 0.0)
                    .offset(y: showTitle ? 0 : 20)
                    .animation(.easeInOut(duration: 0.3), value: showTitle)
                }

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
            .navigationBarTitleDisplayMode(.inline)
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
            
            // Bulk parse HTML content for all comments in background while preserving order
            var parsedComments: [Comment] = []
            for comment in loadedComments {
                // Parse each comment in background but maintain order
                let parsedComment = await withCheckedContinuation { continuation in
                    Task {
                        var updatedComment = comment
                        updatedComment.parsedText = CommentHTMLParser.parseHTMLText(comment.text)
                        continuation.resume(returning: updatedComment)
                    }
                }
                parsedComments.append(parsedComment)
            }
            
            comments = parsedComments
            commentsController.comments = parsedComments
            currentPost.commentsCount = parsedComments.count
            refreshTrigger.toggle() // Ensure visibleComments updates
        } catch {
            print("Error loading comments: \(error)")
            // TODO: Show error state
        }

        isLoading = false
    }

    private func toggleCommentVisibility(_ comment: Comment, scrollTo: @escaping (String) -> Void) {
        withAnimation(.easeInOut(duration: 0.3)) {
            let (_, newVisibility) = commentsController.toggleChildrenVisibility(of: comment)
            // Force SwiftUI to re-evaluate visibleComments
            refreshTrigger.toggle()
            
            // Only scroll when collapsing comments (newVisibility == .hidden means children were hidden)
            if newVisibility == .hidden {
                // Check if the comment is currently visible on screen
                let isCommentVisible = isCommentVisibleOnScreen(comment)
                
                // Only scroll if the comment is not visible
                if !isCommentVisible {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scrollTo("comment-\(comment.id)")
                    }
                }
            }
        }
    }
    
    private func isCommentVisibleOnScreen(_ comment: Comment) -> Bool {
        guard let commentFrame = visibleCommentPositions[comment.id] else {
            return false
        }
        
        // Get the screen bounds
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return false
        }
        
        let screenBounds = window.bounds
        
        // Check if the top of the comment is within the visible screen area
        // We only consider it visible if the top edge is on screen
        return screenBounds.contains(CGPoint(x: commentFrame.midX, y: commentFrame.minY))
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

    private func handleLinkTap() {
        LinkOpener.openURL(currentPost.url, with: currentPost)
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Thumbnail with proper loading
                ThumbnailView(url: UserDefaults.standard.showThumbnails ? post.url : nil)
                    .frame(width: 55, height: 55)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 4) {
                    // Title
                    Text(post.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

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
                                    .font(.caption2)
                            }
                        }

                        Text("•")
                            .foregroundColor(.secondary)

                        HStack(spacing: 0) {
                            Text("\(post.commentsCount)")
                                .foregroundColor(.secondary)
                            Image(systemName: "message")
                                .foregroundColor(.secondary)
                                .font(.caption2)
                        }

                        if let host = post.url.host, !post.url.absoluteString.starts(with: "item?id=") {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(host)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .font(.subheadline)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onLinkTap()
            }

            if let text = post.text,
               !text.isEmpty {
               let parsedText = CommentHTMLParser.parseHTMLText(text)
                Text(parsedText)
                    .foregroundColor(.primary)
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            Divider()
                .padding(.bottom, 6)

            HStack {
                Text(comment.by)
                    .font(.headline)
                    .foregroundColor(comment.by == post.by ? Color(UIColor(named: "appTintColor")!) : .primary)

                Text(comment.age)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if comment.upvoted {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Color(UIColor(named: "upvotedColor")!))
                        .font(.body)
                }

                // Show visibility indicator
                if comment.visibility == .compact {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Use pre-parsed content instead of parsing on render
            if comment.visibility == .visible {
                if let parsedText = comment.parsedText {
                    Text(parsedText)
                        .foregroundColor(.primary)
                        .padding(.bottom, 16)
                } else {
                    // Fallback for comments without parsed text
                    Text(comment.text)
                        .foregroundColor(.primary)
                        .padding(.bottom, 16)
                }
            } else {
                // it's here to maintain row height consistency with List animations
                Spacer()
            }
        }
        .padding(.leading, CGFloat(comment.level * 16))
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        // fix row height animations with List:
        // https://stackoverflow.com/questions/65612622/swift-ui-list-animation-for-expanding-cells-with-dynamic-heights
        .id(String(comment.id) + String(comment.visibility.rawValue))
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

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct CommentPosition: Equatable {
    let id: Int
    let frame: CGRect
}

struct CommentPositionKey: PreferenceKey {
    typealias Value = CommentPosition?
    static var defaultValue: CommentPosition? = nil
    static func reduce(value: inout CommentPosition?, nextValue: () -> CommentPosition?) {
        value = nextValue() ?? value
    }
}
