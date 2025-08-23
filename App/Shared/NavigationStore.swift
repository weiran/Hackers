//
//  NavigationStore.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI
import Combine
import Shared
import Domain

class NavigationStore: ObservableObject, NavigationStoreProtocol {
    @Published var selectedPost: Domain.Post? // Using Domain.Post for protocol conformance
    @Published var selectedHackersKitPost: Post? // Keep old Post for compatibility
    @Published var selectedPostType: PostType = .news
    @Published var showingLogin = false
    @Published var showingSettings = false
    @Published var pendingPostId: Int?

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Listen for refresh notifications
        NotificationCenter.default.publisher(for: Notification.Name.refreshRequired)
            .sink { [weak self] _ in
                // Trigger refresh
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func showPost(_ post: Domain.Post) {
        selectedPost = post
        selectedHackersKitPost = post.toHackersKit()
    }

    // Overload for HackersKit Post during migration
    func showPost(_ post: Post) {
        selectedPost = post.toDomain()
        selectedHackersKitPost = post
    }

    func clearSelection() {
        selectedPost = nil
        selectedHackersKitPost = nil
    }

    func showLogin() {
        showingLogin = true
    }

    func showSettings() {
        showingSettings = true
    }

    func selectPostType(_ type: Domain.PostType) {
        selectedPostType = type.toHackersKit()
        clearSelection()
    }

    // Overload for HackersKit PostType during migration
    func selectPostType(_ postType: PostType) {
        selectedPostType = postType
        clearSelection()
    }

    // MARK: - Deep Linking

    func handleOpenURL(_ url: URL) {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier,
              let scheme = url.scheme,
              scheme.localizedCaseInsensitiveCompare(bundleIdentifier) == .orderedSame,
              let view = url.host else {
            return
        }

        let parameters = parseParameters(from: url)

        switch view {
        case "item":
            if let idString = parameters["id"],
               let id = Int(idString) {
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

        // Create a temporary post object for immediate navigation
        // This will be replaced with the actual post data when loaded
        let tempPost = Post(
            id: id,
            url: URL(string: "\(HackerNewsConstants.baseURL)/item?id=\(id)")!,
            title: "Loading...",
            age: "",
            commentsCount: 0,
            by: "",
            score: 0,
            postType: .news,
            upvoted: false
        )

        showPost(tempPost)
    }
}
