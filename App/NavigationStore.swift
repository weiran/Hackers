//
//  NavigationStore.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Combine
import Domain
import Observation
import Shared
import SwiftUI
import UIKit

enum NavigationDestination: Hashable {
    case comments(postID: Int)
    case settings
}

enum NavigationDetailDestination: Hashable {
    case web(URL)
}

@MainActor
@Observable
class NavigationStore: NavigationStoreProtocol {
    var path: NavigationPath = .init()
    var selectedPost: Domain.Post?
    var selectedPostId: Int?
    var selectedPostType: Domain.PostType = .news
    var showingLogin = false
    var showingSettings = false
    var pendingPostId: Int?
    var embeddedBrowserURL: URL?
    var detailPath: [NavigationDetailDestination] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Listen for refresh notifications
        NotificationCenter.default.publisher(for: Notification.Name.refreshRequired)
            .sink { [weak self] _ in
                self?.path = self?.path ?? .init()
            }
            .store(in: &cancellables)
    }

    func showPost(_ post: Domain.Post) {
        embeddedBrowserURL = nil
        detailPath.removeAll()
        selectedPost = post
        selectedPostId = post.id

        // For iPhone navigation, use NavigationPath
        if UIDevice.current.userInterfaceIdiom != .pad {
            path.append(NavigationDestination.comments(postID: post.id))
        }
    }

    func showPost(withId id: Int) {
        embeddedBrowserURL = nil
        detailPath.removeAll()
        selectedPost = nil
        selectedPostId = id

        if UIDevice.current.userInterfaceIdiom != .pad {
            path.append(NavigationDestination.comments(postID: id))
        }
    }

    func clearSelection() {
        selectedPost = nil
        selectedPostId = nil
        embeddedBrowserURL = nil
        detailPath.removeAll()
    }

    func showLogin() {
        showingLogin = true
    }

    func showSettings() {
        showingSettings = true
    }

    func selectPostType(_ type: Domain.PostType) {
        selectedPostType = type
        selectedPostId = nil
        clearSelection()
    }

    @MainActor
    func openURLInPrimaryContext(_ url: URL, pushOntoDetailStack: Bool = true) -> Bool {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return false }
        guard url.scheme == "http" || url.scheme == "https" else { return false }

        let settings = DependencyContainer.shared.getSettingsUseCase()
        if settings.openInDefaultBrowser {
            return false
        }

        if pushOntoDetailStack, selectedPost != nil {
            detailPath.append(.web(url))
            return true
        }

        embeddedBrowserURL = url
        detailPath.removeAll()
        return true
    }

    @MainActor
    func dismissEmbeddedBrowser() {
        let dismiss = { [weak self] in
            guard let self else { return }
            if !detailPath.isEmpty {
                detailPath.removeLast()
            } else {
                embeddedBrowserURL = nil
            }
        }

        withAnimation(.easeInOut(duration: 0.25)) {
            dismiss()
        }
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
               let id = Int(idString)
            {
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
