//
//  NavigationStoreProtocol.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import Observation

public enum PostLinkPresentation: Hashable, Sendable {
    case collapsedBrowser
    case expandedComments
}

@MainActor
public protocol NavigationStoreProtocol: AnyObject, Observable {
    var selectedPost: Post? { get set }
    var selectedPostId: Int? { get set }
    var showingLogin: Bool { get set }
    var showingSettings: Bool { get set }
    func showPost(_ post: Post)
    func showPostLink(_ post: Post, presentation: PostLinkPresentation)
    func showPost(withId id: Int)
    func showLogin()
    func showSettings()
    func selectPostType(_ type: PostType)
    func openURLInPrimaryContext(_ url: URL, pushOntoDetailStack: Bool) -> Bool
    func commentScrollAnchor(for postID: Int) -> Int?
    func setCommentScrollAnchor(_ commentID: Int?, for postID: Int)
}

public extension NavigationStoreProtocol {
    func showPostLink(_ post: Post) {
        showPostLink(post, presentation: .collapsedBrowser)
    }

    func openURLInPrimaryContext(_ url: URL) -> Bool {
        openURLInPrimaryContext(url, pushOntoDetailStack: true)
    }

    /// Stores navigation continuity rather than persistent reading history. Implementations
    /// that don't own navigation state (for example test doubles) can use these defaults.
    func commentScrollAnchor(for _: Int) -> Int? { nil }
    func setCommentScrollAnchor(_: Int?, for _: Int) {}
}
