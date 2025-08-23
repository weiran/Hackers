import Foundation
import Domain
import Shared
import SwiftUI

@Observable
public final class FeedViewModel: @unchecked Sendable {
    public var posts: [Domain.Post] = []
    public var isLoading = false
    public var isLoadingMore = false
    public var postType: Domain.PostType = .news
    public var error: Error?

    private var postIds: Set<Int> = Set()
    private var pageIndex = 1
    private var lastPostId = 0
    private var isFetching = false

    private let postUseCase: any PostUseCase
    private let voteUseCase: any VoteUseCase

    public init(
        postUseCase: any PostUseCase = DependencyContainer.shared.getPostUseCase(),
        voteUseCase: any VoteUseCase = DependencyContainer.shared.getVoteUseCase()
    ) {
        self.postUseCase = postUseCase
        self.voteUseCase = voteUseCase
    }

    @MainActor
    public func loadFeed() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil
        reset()

        do {
            let fetchedPosts = try await postUseCase.getPosts(
                type: postType,
                page: pageIndex,
                nextId: lastPostId > 0 ? lastPostId : nil
            )

            let newPosts = fetchedPosts.filter { !self.postIds.contains($0.id) }
            let newPostIds = newPosts.map { $0.id }
            self.posts.append(contentsOf: newPosts)
            self.postIds.formUnion(newPostIds)

            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    @MainActor
    public func loadNextPage() async {
        guard !isLoadingMore && !isLoading && !posts.isEmpty else { return }

        isLoadingMore = true

        if postType == .newest || postType == .jobs {
            lastPostId = posts.last?.id ?? lastPostId
        } else {
            pageIndex += 1
        }

        do {
            let fetchedPosts = try await postUseCase.getPosts(
                type: postType,
                page: pageIndex,
                nextId: lastPostId > 0 ? lastPostId : nil
            )

            let newPosts = fetchedPosts.filter { !self.postIds.contains($0.id) }
            let newPostIds = newPosts.map { $0.id }
            self.posts.append(contentsOf: newPosts)
            self.postIds.formUnion(newPostIds)

            isLoadingMore = false
        } catch {
            self.error = error
            isLoadingMore = false
        }
    }

    @MainActor
    public func vote(on post: Domain.Post, upvote: Bool) async throws {
        if upvote {
            try await voteUseCase.upvote(post: post)
        } else {
            try await voteUseCase.unvote(post: post)
        }
    }

    @MainActor
    public func changePostType(_ newType: Domain.PostType) async {
        guard postType != newType else { return }

        postType = newType
        await loadFeed()
    }

    private func reset() {
        posts = []
        postIds = Set()
        pageIndex = 1
        lastPostId = 0
        isFetching = false
    }
}
