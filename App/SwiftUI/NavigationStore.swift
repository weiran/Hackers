//
//  NavigationStore.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI
import Combine

class NavigationStore: ObservableObject {
    @Published var selectedPost: Post?
    @Published var selectedPostType: PostType = .news
    @Published var showingLogin = false
    @Published var showingSettings = false
    
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
    
    func showPost(_ post: Post) {
        selectedPost = post
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
    
    func selectPostType(_ postType: PostType) {
        selectedPostType = postType
        clearSelection()
    }
}