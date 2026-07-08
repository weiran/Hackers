//
//  ExtensionsTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain // Import Domain for PostType only
import Foundation
@testable import Shared
import Testing

@Suite("Extensions Tests")
struct ExtensionsTests {
    // MARK: - PostType Extensions Tests

    @Suite("PostType Extensions")
    struct PostTypeExtensionsTests {
        @Test("PostType displayName returns correct values")
        func postTypeDisplayName() {
            #expect(PostType.news.displayName == "Top")
            #expect(PostType.ask.displayName == "Ask")
            #expect(PostType.show.displayName == "Show")
            #expect(PostType.jobs.displayName == "Jobs")
            #expect(PostType.newest.displayName == "New")
            #expect(PostType.best.displayName == "Best")
            #expect(PostType.active.displayName == "Active")
            #expect(PostType.bookmarks.displayName == "Bookmarks")
        }

        @Test("PostType iconName returns valid SF Symbol names")
        func postTypeIconName() {
            #expect(PostType.news.iconName == "flame")
            #expect(PostType.ask.iconName == "bubble.left.and.bubble.right")
            #expect(PostType.show.iconName == "eye")
            #expect(PostType.jobs.iconName == "briefcase")
            #expect(PostType.newest.iconName == "clock")
            #expect(PostType.best.iconName == "star")
            #expect(PostType.active.iconName == "bolt")
            #expect(PostType.bookmarks.iconName == "bookmark")
        }

        @Test("All PostType cases have displayName")
        func allPostTypesHaveDisplayName() {
            let allCases = PostType.allCases

            for postType in allCases {
                #expect(postType.displayName.isEmpty == false)
                #expect(postType.iconName.isEmpty == false)
            }
        }
    }
}
