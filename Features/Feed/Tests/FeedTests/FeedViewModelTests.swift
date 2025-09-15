//
//  FeedViewModelTests.swift
//  FeedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
@testable import Feed
import Testing

@Suite("FeedViewModel Tests")
struct FeedViewModelTests {
    @Test("FeedViewModel initializes with correct default state")
    func initialState() {
        let viewModel = FeedViewModel()

        #expect(viewModel.posts.count == 0)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.isLoadingMore == false)
        #expect(viewModel.postType == .news)
        #expect(viewModel.error == nil)
    }

    @Test("FeedViewModel changes post type correctly")
    func changePostType() async {
        let viewModel = FeedViewModel()

        let initialType = viewModel.postType
        #expect(initialType == .news)

        await viewModel.changePostType(.ask)
        #expect(viewModel.postType == .ask)
    }
}
