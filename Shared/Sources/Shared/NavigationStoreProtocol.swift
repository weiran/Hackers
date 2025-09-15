//
//  NavigationStoreProtocol.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation

public protocol NavigationStoreProtocol: ObservableObject {
    var selectedPost: Post? { get set }
    var showingLogin: Bool { get set }
    var showingSettings: Bool { get set }
    func showPost(_ post: Post)
    func showLogin()
    func showSettings()
    func selectPostType(_ type: PostType)
}
