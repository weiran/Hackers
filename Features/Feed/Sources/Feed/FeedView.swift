import DesignSystem
import Domain
import Shared
import SwiftUI

public struct FeedView<Store: NavigationStoreProtocol>: View {
    @Environment(Store.self) private var navigationStore
    let isSidebar: Bool
    @State private var viewModel: FeedViewModel
    @State private var votingViewModel: VotingViewModel
    @State private var selectedPostType: Domain.PostType
    @State private var selectedPostId: Int?
    @State private var searchText: String

    public init(
        viewModel: FeedViewModel = FeedViewModel(),
        votingViewModel: VotingViewModel? = nil,
        isSidebar: Bool = false
    ) {
        _viewModel = State(initialValue: viewModel)
        _selectedPostType = State(initialValue: viewModel.postType)
        let container = DependencyContainer.shared
        let defaultVotingViewModel = VotingViewModel(
            votingStateProvider: container.getVotingStateProvider(),
            commentVotingStateProvider: container.getCommentVotingStateProvider(),
            authenticationUseCase: container.getAuthenticationUseCase()
        )
        _votingViewModel = State(initialValue: votingViewModel ?? defaultVotingViewModel)
        _searchText = State(initialValue: viewModel.searchQuery)
        self.isSidebar = isSidebar
    }

    public var body: some View {
        contentView
            .navigationTitle(viewModel.hasActiveSearch ? "Search" : selectedPostType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    settingsButton
                }
                ToolbarSpacer(.flexible, placement: .bottomBar)
                DefaultToolbarItem(kind: .search, placement: .bottomBar)
            }
            .toolbarTitleMenu {
                if !viewModel.hasActiveSearch {
                    postTypeTitleMenu
                }
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: "Search Hacker News")
            .searchToolbarBehavior(.minimize)
            .onChange(of: searchText) { _, newValue in
                viewModel.updateSearchQuery(newValue)
            }
            .onChange(of: viewModel.searchQuery) { _, newValue in
                if newValue != searchText {
                    searchText = newValue
                }
            }
            .onChange(of: selectedPostType) { _, _ in
                selectedPostId = nil
            }
            .task { @Sendable in
                votingViewModel.navigationStore = navigationStore
                await viewModel.loadFeed()
            }
            .onChange(of: navigationStore.selectedPost) { _, newPost in
                if let updatedPost = newPost {
                    viewModel.replacePost(updatedPost)
                }
            }
            .alert(
                "Vote Error",
                isPresented: Binding(
                    get: { votingViewModel.lastError != nil },
                    set: { newValue in
                        if newValue == false { votingViewModel.clearError() }
                    },
                ),
            ) {
                Button("OK") { votingViewModel.clearError() }
            } message: {
                Text(votingViewModel.lastError?.localizedDescription ?? "Failed to vote. Please try again.")
            }
            .onAppear {
                votingViewModel.navigationStore = navigationStore
            }
    }
}

private extension FeedView {
    var primaryPostTypes: [Domain.PostType] {
        [.news, .ask, .show, .jobs, .newest, .best, .active]
    }

    var secondaryPostTypes: [Domain.PostType] {
        [.bookmarks]
    }

    var shouldShowBookmarksEmptyState: Bool {
        viewModel.postType == .bookmarks
            && viewModel.posts.isEmpty
            && !viewModel.isLoading
            && !viewModel.hasActiveSearch
    }

    var selectionBinding: Binding<Int?> {
        if isSidebar {
            Binding(
                get: { selectedPostId },
                set: { newPostId in
                    if let postId = newPostId,
                       let selectedPost = viewModel.posts.first(where: { $0.id == postId }) {
                        selectedPostId = postId
                        handlePostTap(post: selectedPost)
                    }
                }
            )
        } else {
            .constant(nil)
        }
    }

    var contentView: some View {
        Group {
            if viewModel.hasActiveSearch {
                searchContentView
            } else if viewModel.isLoading && viewModel.posts.isEmpty && viewModel.postType != .bookmarks {
                AppLoadingStateView(message: "Loading...")
            } else if shouldShowBookmarksEmptyState {
                AppEmptyStateView(
                    iconSystemName: "bookmark",
                    title: "No bookmarks yet",
                    subtitle: "Save stories to keep them here."
                )
            } else {
                feedListView(posts: viewModel.posts, enablePagination: true)
                    .refreshable {
                        await viewModel.refreshFeed()
                    }
            }
        }
        .animation(.default, value: viewModel.hasActiveSearch)
    }

    @ViewBuilder
    private var searchContentView: some View {
        VStack(spacing: 0) {
            searchFilterBar
            Divider()
            searchResultsContent
        }
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        if viewModel.isSearchInProgress && viewModel.searchResults.isEmpty {
            ProgressView("Searching...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.searchError, viewModel.searchResults.isEmpty {
            AppEmptyStateView(
                iconSystemName: "exclamationmark.triangle",
                title: "Search Failed",
                subtitle: error.localizedDescription
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.searchResults.isEmpty {
            AppEmptyStateView(
                iconSystemName: "magnifyingglass",
                title: "No Results",
                subtitle: "Try a different query."
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            feedListView(posts: viewModel.searchResults, enablePagination: false, enableSearchPagination: true)
        }
    }

    private func feedListView(
        posts: [Domain.Post],
        enablePagination: Bool,
        enableSearchPagination: Bool = false
    ) -> some View {
        List(selection: selectionBinding) {
            ForEach(posts, id: \.id) { post in
                postRow(
                    for: post,
                    enablePagination: enablePagination,
                    enableSearchPagination: enableSearchPagination
                )
            }
            if enableSearchPagination {
                searchPaginationFooter
            }
        }
        .if(isSidebar) { view in view.listStyle(.sidebar) }
        .if(!isSidebar) { view in view.listStyle(.plain) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .id(selectedPostType)
        .accessibilityIdentifier("feed.list")
    }

    private func postRow(
        for post: Domain.Post,
        enablePagination: Bool = true,
        enableSearchPagination: Bool = false
    ) -> some View {
        PostRowView(
            post: post,
            votingViewModel: votingViewModel,
            showThumbnails: viewModel.showThumbnails,
            compactMode: viewModel.compactFeedDesign,
            dimReadPost: viewModel.dimReadPosts,
            onLinkTap: { handleLinkTap(post: post) },
            onCommentsTap: isSidebar ? nil : { handlePostTap(post: post) },
            onPostUpdated: { updatedPost in
                viewModel.replacePost(updatedPost)
            },
            onBookmarkToggle: {
                await viewModel.toggleBookmark(for: post)
            }
        )
        .if(isSidebar) { view in
            view.tag(post.id)
        }
        .onAppear {
            if enablePagination, post == viewModel.posts.last {
                Task {
                    await viewModel.loadNextPage()
                }
            }
            if enableSearchPagination, post == viewModel.searchResults.last {
                Task {
                    await viewModel.loadNextSearchPage()
                }
            }
        }
        .if(shouldShowVoteActions(for: post)) { view in
            view.swipeActions(edge: .leading, allowsFullSwipe: true) {
                voteSwipeAction(for: post)
            }
        }
        .listRowSeparator(.hidden, edges: .top)
        .listRowSeparator(.visible, edges: .bottom)
        .contextMenu { contextMenuContent(for: post) }
        .accessibilityIdentifier("feed.post.\(post.id)")
    }

    @ViewBuilder
    private func voteSwipeAction(for post: Domain.Post) -> some View {
        if post.upvoted && post.voteLinks?.unvote != nil {
            Button {
                Task {
                    var mutablePost = post
                    await votingViewModel.unvote(post: &mutablePost)
                    await MainActor.run {
                        if !mutablePost.upvoted {
                            if let existingLinks = mutablePost.voteLinks {
                                mutablePost.voteLinks = VoteLinks(upvote: existingLinks.upvote, unvote: nil)
                            }
                            viewModel.replacePost(mutablePost)
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.uturn.down")
            }
            .tint(.orange)
            .accessibilityLabel("Unvote")
        } else {
            Button {
                Task {
                    var mutablePost = post
                    await votingViewModel.upvote(post: &mutablePost)
                    await MainActor.run {
                        if mutablePost.upvoted {
                            viewModel.replacePost(mutablePost)
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up")
            }
            .tint(AppColors.upvotedColor)
            .accessibilityLabel("Upvote")
        }
    }

    @ViewBuilder
    private func contextMenuContent(for post: Domain.Post) -> some View {
        VotingContextMenuItems.postVotingMenuItems(
            for: post,
            onVote: {
                Task {
                    var mutablePost = post
                    await votingViewModel.upvote(post: &mutablePost)
                    await MainActor.run {
                        if mutablePost.upvoted {
                            viewModel.replacePost(mutablePost)
                        }
                    }
                }
            },
            onUnvote: {
                Task {
                    var mutablePost = post
                    await votingViewModel.unvote(post: &mutablePost)
                    await MainActor.run {
                        if !mutablePost.upvoted {
                            if let existingLinks = mutablePost.voteLinks {
                                mutablePost.voteLinks = VoteLinks(upvote: existingLinks.upvote, unvote: nil)
                            }
                            viewModel.replacePost(mutablePost)
                        }
                    }
                }
            }
        )

        Divider()

        if !isHackerNewsItemURL(post.url) {
            Button { handleLinkTap(post: post) } label: {
                Label("Open Link", systemImage: "safari")
            }
        }

        Button {
            Task {
                _ = await viewModel.toggleBookmark(for: post)
            }
        } label: {
            Label(
                post.isBookmarked ? "Remove Bookmark" : "Save Bookmark",
                systemImage: post.isBookmarked ? "bookmark.slash" : "bookmark"
            )
        }

        Button { ContentSharePresenter.shared.sharePost(post) } label: {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }

    @ViewBuilder
    private var postTypeTitleMenu: some View {
        ForEach(primaryPostTypes, id: \.self) { postType in
            postTypeMenuButton(for: postType)
        }
        if !secondaryPostTypes.isEmpty {
            Divider()
            ForEach(secondaryPostTypes, id: \.self) { postType in
                postTypeMenuButton(for: postType)
            }
        }
    }

    private var settingsButton: some View {
        Button {
            navigationStore.showSettings()
        } label: {
            Image(systemName: "gearshape")
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .accessibilityLabel("Settings")
        .accessibilityIdentifier("settings.button")
    }

    private var searchSortMenu: some View {
        Menu {
            ForEach(SearchSort.allCases, id: \.self) { sort in
                Button {
                    viewModel.updateSearchSort(sort)
                } label: {
                    HStack {
                        Text(sort.displayName)
                        if sort == viewModel.searchSort {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label(viewModel.searchSort.displayName, systemImage: "arrow.up.arrow.down")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityIdentifier("search.sort.menu")
    }

    private var searchDateRangeMenu: some View {
        Menu {
            ForEach(SearchDateRange.allCases, id: \.self) { dateRange in
                Button {
                    viewModel.updateSearchDateRange(dateRange)
                } label: {
                    HStack {
                        Text(dateRange.displayName)
                        if dateRange == viewModel.searchDateRange {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label(viewModel.searchDateRange.displayName, systemImage: "calendar")
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .accessibilityIdentifier("search.date.menu")
    }

    private var searchFilterBar: some View {
        HStack(spacing: 12) {
            searchSortMenu
            searchDateRangeMenu
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    @ViewBuilder
    private var searchPaginationFooter: some View {
        if viewModel.isLoadingMoreSearchResults {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .listRowSeparator(.hidden)
        } else if let error = viewModel.searchError, !viewModel.searchResults.isEmpty {
            Text(error.localizedDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
        }
    }

    private func postTypeMenuButton(for postType: Domain.PostType) -> some View {
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
        .accessibilityIdentifier("feed.category.\(postType.rawValue)")
    }

    private func handlePostTap(post: Domain.Post) {
        viewModel.markPostRead(post)
        let mode = DependencyContainer.shared.getSettingsUseCase().linkBrowserMode
        if mode == .customBrowser {
            navigationStore.showPostLink(post)
            return
        }
        navigationStore.showPost(post)
    }

    private func handleLinkTap(post: Domain.Post) {
        guard !isHackerNewsItemURL(post.url) else {
            navigationStore.showPost(post)
            return
        }

        let mode = DependencyContainer.shared.getSettingsUseCase().linkBrowserMode
        if mode == .customBrowser, UIDevice.current.userInterfaceIdiom != .pad {
            navigationStore.showPostLink(post)
            return
        }

        if isSidebar {
            navigationStore.showPost(post)
            selectedPostId = post.id
        }

        if navigationStore.openURLInPrimaryContext(post.url, pushOntoDetailStack: !isSidebar) {
            return
        }
        LinkOpener.openURL(post.url, with: post)
    }

    private func isHackerNewsItemURL(_ url: URL) -> Bool {
        guard let hnHost = url.host else { return false }
        return hnHost == Shared.HackerNewsConstants.host && url.path == "/item"
    }

    private func shouldShowVoteActions(for post: Domain.Post) -> Bool {
        (post.voteLinks?.upvote != nil && !post.upvoted)
            || (post.voteLinks?.unvote != nil && post.upvoted)
    }
}

private extension SearchSort {
    var displayName: String {
        switch self {
        case .popular:
            "Popular"
        case .recent:
            "Recent"
        }
    }
}

private extension SearchDateRange {
    var displayName: String {
        switch self {
        case .allTime:
            "All Time"
        case .last24Hours:
            "Last 24 Hours"
        case .pastWeek:
            "Past Week"
        case .pastMonth:
            "Past Month"
        case .pastYear:
            "Past Year"
        }
    }
}
