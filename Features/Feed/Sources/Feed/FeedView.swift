import SwiftUI
import Domain
import Shared

// Simple PostRow component for now
struct PostRow: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(post.title)
                .font(.headline)
                .lineLimit(2)
            
            HStack {
                Text("\(post.score) points")
                Text("•")
                Text("by \(post.by)")
                Text("•")
                Text("\(post.commentsCount) comments")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

public struct CleanFeedView<NavigationStore: NavigationStoreProtocol>: View {
    @State private var viewModel: FeedViewModel
    @State private var selectedPostType: PostType = .news
    @State private var selectedPostId: Int?
    @EnvironmentObject private var navigationStore: NavigationStore
    
    let isSidebar: Bool
    
    public init(
        viewModel: FeedViewModel = FeedViewModel(),
        isSidebar: Bool = false
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.isSidebar = isSidebar
    }
    
    private var selectionBinding: Binding<Int?> {
        isSidebar ? $selectedPostId : .constant(nil)
    }
    
    public var body: some View {
        NavigationStack {
            if viewModel.isLoading && viewModel.posts.isEmpty {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: selectionBinding) {
                    ForEach(viewModel.posts, id: \.id) { post in
                        PostRow(post: post)
                            .onTapGesture {
                                if isSidebar {
                                    selectedPostId = post.id
                                }
                                navigationStore.showPost(post)
                            }
                            .onAppear {
                                if post == viewModel.posts.last {
                                    Task {
                                        await viewModel.loadNextPage()
                                    }
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
        }
        .task { @Sendable in
            await viewModel.loadFeed()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
}