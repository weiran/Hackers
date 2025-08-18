//
//  CommentsView.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI
import SafariServices

// Wrapper to make post ID identifiable for navigation
struct PostNavigation: Identifiable, Hashable {
    let id: Int
}

// swiftlint:disable:next type_body_length
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
    @State private var hasInitializedTitleVisibility = false
    @State private var headerHeight: CGFloat = 0
    @State private var visibleCommentPositions: [Int: CGRect] = [:]
    @State private var navigateToPost: PostNavigation?
    @State private var hasLoadedComments = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

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
        VStack(alignment: .leading, spacing: 0) {
                // Comments section
                ScrollViewReader { proxy in
                    List {
                        PostDisplayView(
                            post: currentPost,
                            showVoteButton: true,
                            showPostText: true,
                            onVote: { await handlePostVote() },
                            onLinkTap: { handleLinkTap() }
                        )
                        .padding()
                        .id("header")
                        .background(GeometryReader { geometry in
                            Color.clear.preference(
                                key: ViewOffsetKey.self,
                                value: geometry.frame(in: .global).minY
                            )
                        })
                        .onPreferenceChange(ViewOffsetKey.self) { offset in
                            if !hasInitializedTitleVisibility {
                                // On first load, set without animation to prevent flash
                                showTitle = offset < 50
                                hasInitializedTitleVisibility = true
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    // Show title when header scrolls above navigation bar (approximately)
                                    showTitle = offset < 50
                                }
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if UserDefaults.standard.swipeActionsEnabled {
                                Button {
                                    Task { await handlePostVote() }
                                } label: {
                                    Image(systemName: currentPost.upvoted ? "arrow.uturn.down" : "arrow.up")
                                }
                                .tint(currentPost.upvoted ? .secondary : Color("upvotedColor"))
                            }
                        }
                        .contextMenu {
                            PostContextMenu(
                                post: currentPost,
                                onVote: { Task { await handlePostVote() } },
                                onOpenLink: { handleLinkTap() },
                                onShare: { showingPostShareOptions = true }
                            )
                        }
                        .plainListRow()

                        if isLoading {
                            VStack {
                                Spacer()
                                ProgressView()
                                Text("Loading comments...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .plainListRow()
                        } else if comments.isEmpty {
                            Text("No comments yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                            .plainListRow()
                        } else {
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
                                    onCopy: { copyComment(comment) },
                                    onHide: {
                                        if let rootIndex = commentsController.indexOfVisibleRootComment(of: comment) {
                                            let rootComment = commentsController.visibleComments[rootIndex]
                                            toggleCommentVisibility(rootComment) { id in
                                                proxy.scrollTo(id, anchor: .top)
                                            }
                                        }
                                    }
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
                                .authenticationDialog(isPresented: $showingAuthenticationDialog) {
                                    navigationStore.showLogin()
                                }
                                .plainListRow()
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        ThumbnailView(url: UserDefaults.standard.showThumbnails ? currentPost.url : nil)
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
                    .opacity(hasInitializedTitleVisibility ? (showTitle ? 1.0 : 0.0) : 0.0)
                    .offset(y: showTitle ? 0 : 20)
                    .animation(hasInitializedTitleVisibility ? .easeInOut(duration: 0.3) : nil, value: showTitle)
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
                await loadComments(forceReload: true)
            }
            .task(id: post.id) {
                // Only load if we haven't loaded comments for this post yet
                if !hasLoadedComments {
                    await loadComments()
                }
            }
            .alert("Vote Error", isPresented: $showingVoteError) {
                Button("OK") { }
            } message: {
                Text(voteErrorMessage)
            }
            .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $navigateToPost) { postNav in
            // Create a temporary post for navigation
            let tempPost = Post(
                id: postNav.id,
                url: URL(string: "\(HackerNewsConstants.baseURL)/item?id=\(postNav.id)")!,
                title: "Loading...",
                age: "",
                commentsCount: 0,
                by: "",
                score: 0,
                postType: .news,
                upvoted: false
            )
            CommentsView(post: tempPost)
                .environmentObject(navigationStore)
                .id(postNav.id) // Force unique identity for each CommentsView
        }
        .environment(\.openURL, OpenURLAction { url in
            // Check if it's a Hacker News item URL
            if url.host?.localizedCaseInsensitiveCompare(HackerNewsConstants.host) == .orderedSame,
               let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let id = Int(idString) {
                // Navigate to the post's comments
                navigateToPost = PostNavigation(id: id)
                return .handled
            }

            // For all other URLs, open them normally
            LinkOpener.openURL(url)
            return .handled
        })
    }

    private func loadComments(forceReload: Bool = false) async {
        // Skip loading if we already have comments and not forcing reload
        if hasLoadedComments && !forceReload && !comments.isEmpty {
            return
        }

        isLoading = true

        do {
            // Load post with comments if not already loaded or forcing reload
            let postWithComments: Post
            if currentPost.comments == nil || forceReload {
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
                        let updatedComment = comment
                        var mutableComment = updatedComment
                        mutableComment.parsedText = CommentHTMLParser.parseHTMLText(comment.text)
                        continuation.resume(returning: mutableComment)
                    }
                }
                parsedComments.append(parsedComment)
            }

            comments = parsedComments
            commentsController.comments = parsedComments
            currentPost.commentsCount = parsedComments.count
            refreshTrigger.toggle() // Ensure visibleComments updates
            hasLoadedComments = true // Mark that we've loaded comments
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
        guard let window = PresentationService.shared.windowScene?.windows.first else {
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
        ShareService.shared.shareURL(url, title: title)
    }

    private func shareComment(_ comment: Comment) {
        ShareService.shared.shareComment(comment)
    }

    private func copyComment(_ comment: Comment) {
        UIPasteboard.general.string = comment.text.strippingHTML()
    }
}

struct CommentRowView: View {
    @ObservedObject var comment: Comment
    let post: Post
    let onToggle: () -> Void
    let onVote: () async -> Void
    let onShare: () -> Void
    let onCopy: () -> Void
    let onHide: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.bottom, 6)

            HStack {
                Text(comment.by)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(comment.by == post.by ? Color(UIColor(named: "appTintColor")!) : .primary)

                Text(comment.age)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if comment.upvoted {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Color("upvotedColor"))
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
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if UserDefaults.standard.swipeActionsEnabled {
                Button {
                    Task { await onVote() }
                } label: {
                    Image(systemName: comment.upvoted ? "arrow.uturn.down" : "arrow.up")
                }
                .tint(comment.upvoted ? .secondary : Color("upvotedColor"))
            }
        }
        .swipeActions(edge: .trailing) {
            if UserDefaults.standard.swipeActionsEnabled {
                Button {
                    onHide()
                } label: {
                    Image(systemName: "minus.circle")
                }
            }
        }
        // fix row height animations with List:
        // https://stackoverflow.com/questions/65612622/swift-ui-list-animation-for-expanding-cells-with-dynamic-heights
        .id(String(comment.id) + String(comment.visibility.rawValue))
    }
}

struct CommentContextMenu: View {
    @ObservedObject var comment: Comment
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
    static var defaultValue: CommentPosition?
    static func reduce(value: inout CommentPosition?, nextValue: () -> CommentPosition?) {
        value = nextValue() ?? value
    }
}

struct PlainListRowStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

extension View {
    func plainListRow() -> some View {
        modifier(PlainListRowStyle())
    }
}
