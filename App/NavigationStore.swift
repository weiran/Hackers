//
//  NavigationStore.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Observation
import Shared
import SwiftUI

/// A screen shown in the detail column of the root split view, either as its root or
/// pushed on top. The same model drives compact and regular widths, so the visible
/// screen survives size-class changes such as folding an iPhone Duo.
enum NavigationDetailDestination: Hashable {
    case comments(postID: Int)
    case postBrowser(post: Post, presentation: PostLinkPresentation)
    case web(URL)
}

@MainActor
@Observable
class NavigationStore: NavigationStoreProtocol {
    var selectedPost: Domain.Post?
    var selectedPostId: Int?
    var selectedPostType: Domain.PostType = .news
    var detailRoot: NavigationDetailDestination?
    var detailPath: [NavigationDetailDestination] = []
    /// Which column a collapsed (compact-width) split view shows.
    var preferredCompactColumn: NavigationSplitViewColumn = .sidebar
    var showingLogin = false
    var showingSettings = false
    var pendingPostId: Int?
    private var commentScrollAnchors: [Int: Int] = [:]

    func showPost(_ post: Domain.Post) {
        selectedPost = post
        selectedPostId = post.id
        showDetailRoot(.comments(postID: post.id))
    }

    func showPostLink(_ post: Domain.Post, presentation: PostLinkPresentation) {
        guard !HackerNewsConstants.isItemURL(post.url) else {
            showPost(post)
            return
        }
        selectedPost = post
        selectedPostId = post.id
        showDetailRoot(.postBrowser(post: post, presentation: presentation))
    }

    #if DEBUG
    func showPostLinkForUITesting(_ post: Domain.Post, presentation: PostLinkPresentation) {
        showPostLink(post, presentation: presentation)
    }
    #endif

    func showPost(withId id: Int) {
        selectedPost = nil
        selectedPostId = id
        showDetailRoot(.comments(postID: id))
    }

    func clearSelection() {
        selectedPost = nil
        selectedPostId = nil
        detailRoot = nil
        detailPath.removeAll()
        preferredCompactColumn = .sidebar
        commentScrollAnchors.removeAll()
    }

    func showLogin() {
        showingLogin = true
    }

    func showSettings() {
        showingSettings = true
    }

    func selectPostType(_ type: Domain.PostType) {
        selectedPostType = type
        clearSelection()
    }

    /// Opens a link on top of the current detail screen: Hacker News items as comments,
    /// other web links in the in-app browser. Returns false when the user prefers the
    /// system browser so the caller can hand the link off instead.
    @MainActor
    func openURLInPrimaryContext(_ url: URL, pushOntoDetailStack: Bool = true) -> Bool {
        guard url.scheme == "http" || url.scheme == "https" else { return false }

        let destination: NavigationDetailDestination
        if let itemID = HackerNewsConstants.itemID(from: url) {
            destination = .comments(postID: itemID)
        } else {
            let settings = DependencyContainer.shared.getSettingsUseCase()
            guard settings.linkBrowserMode != .systemBrowser else { return false }
            destination = .web(url)
        }

        if pushOntoDetailStack, detailRoot != nil {
            detailPath.append(destination)
            preferredCompactColumn = .detail
        } else {
            showDetailRoot(destination)
        }
        return true
    }

    func commentScrollAnchor(for postID: Int) -> Int? {
        commentScrollAnchors[postID]
    }

    func setCommentScrollAnchor(_ commentID: Int?, for postID: Int) {
        commentScrollAnchors[postID] = commentID
    }

    /// Closes the top detail screen, returning to the feed when it was the root.
    func dismissDetail() {
        withAnimation(.easeInOut(duration: 0.25)) {
            if !detailPath.isEmpty {
                detailPath.removeLast()
            } else {
                clearSelection()
            }
        }
    }

    private func showDetailRoot(_ destination: NavigationDetailDestination) {
        detailPath.removeAll()
        detailRoot = destination
        preferredCompactColumn = .detail
    }

    // MARK: - Deep Linking

    func handleOpenURL(_ url: URL) {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let scheme = url.scheme,
              scheme.localizedCaseInsensitiveCompare(bundleIdentifier) == .orderedSame,
              let view = url.host
        else {
            return
        }

        let parameters = parseParameters(from: url)

        switch view {
        case "item":
            if let idString = parameters["id"],
               let id = Int(idString), id > 0 {
                navigateToPost(withId: id)
            }
        default:
            break
        }
    }

    private func parseParameters(from url: URL) -> [String: String] {
        var parameters: [String: String] = [:]
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
            parameters[$0.name] = $0.value
        }
        return parameters
    }

    func navigateToPost(withId id: Int) {
        // Store the pending post ID to be handled when posts are loaded
        pendingPostId = id
        showPost(withId: id)
    }
}
