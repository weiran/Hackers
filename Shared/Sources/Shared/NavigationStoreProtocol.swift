//
//  NavigationStoreProtocol.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import Observation

@MainActor
public protocol NavigationStoreProtocol: AnyObject, Observable {
    var selectedPost: Post? { get set }
    var selectedPostId: Int? { get set }
    var showingLogin: Bool { get set }
    var showingSettings: Bool { get set }
    func showPost(_ post: Post)
    func showPost(withId id: Int)
    func showLogin()
    func showSettings()
    func selectPostType(_ type: PostType)
    func openURLInPrimaryContext(_ url: URL, pushOntoDetailStack: Bool) -> Bool
}

public extension NavigationStoreProtocol {
    func openURLInPrimaryContext(_ url: URL) -> Bool {
        openURLInPrimaryContext(url, pushOntoDetailStack: true)
    }
}
