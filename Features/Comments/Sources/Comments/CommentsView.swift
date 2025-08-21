import SwiftUI
import Domain
import Shared
import DesignSystem

public struct CleanCommentsView<NavigationStore: NavigationStoreProtocol>: View {
    @State private var viewModel: CommentsViewModel
    @State private var showingVoteError = false
    @State private var voteErrorMessage = ""
    @State private var showingAuthenticationDialog = false
    @State private var showTitle = false
    @State private var hasMeasuredInitialOffset = false
    @State private var visibleCommentPositions: [Int: CGRect] = [:]
    @State private var navigateToPostId: Int?
    @EnvironmentObject private var navigationStore: NavigationStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    public init(post: Post, viewModel: CommentsViewModel? = nil) {
        self._viewModel = State(initialValue: viewModel ?? CommentsViewModel(post: post))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollViewReader { proxy in
                List {
                    PostHeader(
                        post: viewModel.post,
                        onVote: { await handlePostVote() },
                        onLinkTap: { handleLinkTap() }
                    )
                    .id("header")
                    .background(GeometryReader { geometry in
                        Color.clear.preference(
                            key: ViewOffsetKey.self,
                            value: geometry.frame(in: .global).minY
                        )
                    })
                    .onPreferenceChange(ViewOffsetKey.self) { offset in
                        if !hasMeasuredInitialOffset {
                            hasMeasuredInitialOffset = true
                            showTitle = offset < 50
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showTitle = offset < 50
                            }
                        }
                    }
                    .plainListRow()
                    
                    if viewModel.isLoading {
                        LoadingView()
                            .plainListRow()
                    } else if viewModel.comments.isEmpty {
                        EmptyCommentsView()
                            .plainListRow()
                    } else {
                        ForEach(viewModel.visibleComments, id: \.id) { comment in
                            CommentRow(
                                comment: comment,
                                post: viewModel.post,
                                onToggle: {
                                    toggleCommentVisibility(comment) { id in
                                        proxy.scrollTo(id, anchor: .top)
                                    }
                                },
                                onVote: { await handleCommentVote(comment) },
                                onHide: {
                                    viewModel.hideCommentBranch(comment)
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
                            .plainListRow()
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if hasMeasuredInitialOffset {
                    ToolbarTitle(
                        post: viewModel.post,
                        showTitle: showTitle,
                        onTap: { handleLinkTap() }
                    )
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareMenu(post: viewModel.post)
            }
        }
        .refreshable {
            await viewModel.refreshComments()
        }
        .task(id: viewModel.post.id) {
            await viewModel.loadComments()
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
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $navigateToPostId) { postId in
            let tempPost = Post(
                id: postId,
                url: URL(string: "\(HackerNewsConstants.baseURL)/item?id=\(postId)")!,
                title: "Loading...",
                age: "",
                commentsCount: 0,
                by: "",
                score: 0,
                postType: .news,
                upvoted: false
            )
            CleanCommentsView<NavigationStore>(post: tempPost)
                .environmentObject(navigationStore)
                .id(postId)
        }
        .environment(\.openURL, OpenURLAction { url in
            if url.host?.localizedCaseInsensitiveCompare(HackerNewsConstants.host) == .orderedSame,
               let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let id = Int(idString) {
                navigateToPostId = id
                return .handled
            }
            
            LinkOpener.openURL(url)
            return .handled
        })
    }
    
    @MainActor
    private func handlePostVote() async {
        let isUpvote = !viewModel.post.upvoted
        
        do {
            try await viewModel.voteOnPost(upvote: isUpvote)
        } catch {
            handleVoteError(error)
        }
    }
    
    @MainActor
    private func handleCommentVote(_ comment: Comment) async {
        let isUpvote = !comment.upvoted
        
        do {
            try await viewModel.voteOnComment(comment, upvote: isUpvote)
        } catch {
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
        LinkOpener.openURL(viewModel.post.url, with: viewModel.post)
    }
    
    private func toggleCommentVisibility(_ comment: Comment, scrollTo: @escaping (String) -> Void) {
        withAnimation(.easeInOut(duration: 0.3)) {
            let wasVisible = comment.visibility == .visible
            viewModel.toggleCommentVisibility(comment)
            
            if wasVisible && !isCommentVisibleOnScreen(comment) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollTo("comment-\(comment.id)")
                }
            }
        }
    }
    
    private func isCommentVisibleOnScreen(_ comment: Comment) -> Bool {
        guard let commentFrame = visibleCommentPositions[comment.id] else {
            return false
        }
        
        guard let window = PresentationService.shared.windowScene?.windows.first else {
            return false
        }
        
        let screenBounds = window.bounds
        return screenBounds.contains(CGPoint(x: commentFrame.midX, y: commentFrame.minY))
    }
}

private struct PostHeader: View {
    let post: Post
    let onVote: () async -> Void
    let onLinkTap: () -> Void
    
    var body: some View {
        PostDisplayView(
            post: post,
            showVoteButton: true,
            showPostText: true,
            onVote: onVote,
            onLinkTap: onLinkTap
        )
        .padding()
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // Swipe actions temporarily disabled - need UserDefaults extension
            if false { // UserDefaults.standard.swipeActionsEnabled
                Button {
                    Task { await onVote() }
                } label: {
                    Image(systemName: post.upvoted ? "arrow.uturn.down" : "arrow.up")
                }
                .tint(post.upvoted ? .secondary : Color("upvotedColor"))
            }
        }
        .contextMenu {
            PostContextMenu(
                post: post,
                onVote: { Task { await onVote() } },
                onOpenLink: onLinkTap,
                onShare: { ShareService.shared.shareURL(post.url, title: post.title) }
            )
        }
    }
}

private struct CommentRow: View {
    @ObservedObject var comment: Comment
    let post: Post
    let onToggle: () -> Void
    let onVote: () async -> Void
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
                
                if comment.visibility == .compact {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if comment.visibility == .visible {
                if let parsedText = comment.parsedText {
                    Text(parsedText)
                        .foregroundColor(.primary)
                        .padding(.bottom, 16)
                } else {
                    Text(comment.text)
                        .foregroundColor(.primary)
                        .padding(.bottom, 16)
                }
            } else {
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
            // Swipe actions temporarily disabled - need UserDefaults extension
            if false { // UserDefaults.standard.swipeActionsEnabled
                Button {
                    Task { await onVote() }
                } label: {
                    Image(systemName: comment.upvoted ? "arrow.uturn.down" : "arrow.up")
                }
                .tint(comment.upvoted ? .secondary : Color("upvotedColor"))
            }
        }
        .swipeActions(edge: .trailing) {
            // Swipe actions temporarily disabled - need UserDefaults extension
            if false { // UserDefaults.standard.swipeActionsEnabled
                Button {
                    onHide()
                } label: {
                    Image(systemName: "minus.circle")
                }
            }
        }
        .contextMenu {
            CommentContextMenu(
                comment: comment,
                onVote: { Task { await onVote() } },
                onShare: { ShareService.shared.shareComment(comment) },
                onCopy: { UIPasteboard.general.string = comment.text.strippingHTML() }
            )
        }
        .id(String(comment.id) + String(comment.visibility.rawValue))
    }
}

private struct ToolbarTitle: View {
    let post: Post
    let showTitle: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            ThumbnailView(url: post.url)
                .frame(width: 33, height: 33)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(post.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .onTapGesture {
            onTap()
        }
        .opacity(showTitle ? 1.0 : 0.0)
        .offset(y: showTitle ? 0 : 20)
        .animation(.easeInOut(duration: 0.3), value: showTitle)
    }
}

private struct ShareMenu: View {
    let post: Post
    
    var body: some View {
        Menu {
            if post.url.host != nil {
                Button("Article Link") {
                    ShareService.shared.shareURL(post.url, title: post.title)
                }
                Button("Hacker News Link") {
                    ShareService.shared.shareURL(post.hackerNewsURL, title: post.title)
                }
            } else {
                Button("Hacker News Link") {
                    ShareService.shared.shareURL(post.hackerNewsURL, title: post.title)
                }
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }
}

private struct LoadingView: View {
    var body: some View {
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
    }
}

private struct EmptyCommentsView: View {
    var body: some View {
        Text("No comments yet")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
    }
}

private struct CommentContextMenu: View {
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

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static let defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct CommentPosition: Equatable {
    let id: Int
    let frame: CGRect
}

struct CommentPositionKey: PreferenceKey {
    typealias Value = CommentPosition?
    static let defaultValue: CommentPosition? = nil
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