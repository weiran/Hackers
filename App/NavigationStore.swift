//
//  NavigationStore.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI
import Combine
import Shared
import Domain

enum NavigationDestination: Hashable {
    case comments(Domain.Post)
    case settings
}

class NavigationStore: ObservableObject, NavigationStoreProtocol {
    @Published var path: NavigationPath = NavigationPath()
    @Published var selectedPost: Domain.Post?
    @Published var selectedPostType: Domain.PostType = .news
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

        // For iPhone navigation, use NavigationPath
        if UIDevice.current.userInterfaceIdiom != .pad {
            path.append(NavigationDestination.comments(post))
        }
    }

    func clearSelection() {
        selectedPost = nil
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
        let tempPost = Domain.Post(
            id: id,
            url: URL(string: "\(Domain.HackerNewsConstants.baseURL)/item?id=\(id)")!,
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
