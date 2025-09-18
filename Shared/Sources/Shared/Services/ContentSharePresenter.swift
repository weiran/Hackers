//
//  ContentSharePresenter.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import SwiftUI
import UIKit

public final class ContentSharePresenter: @unchecked Sendable {
    public static let shared = ContentSharePresenter()

    private init() {}

    @MainActor
    public func sharePost(_ post: Post) {
        let items: [Any] = [post.title, post.url]
        showShareSheet(items: items)
    }

    @MainActor
    public func shareURL(_ url: URL, title: String? = nil) {
        var items: [Any] = []
        if let title {
            items.append(title)
        }
        items.append(url)
        showShareSheet(items: items)
    }

    @MainActor
    public func shareComment(_ comment: Comment) {
        let text = comment.text.strippingHTML()
        let items: [Any] = [text]
        showShareSheet(items: items)
    }

    @MainActor
    private func showShareSheet(items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let rootViewController = PresentationContextProvider.shared.rootViewController
        {
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                            y: rootViewController.view.bounds.midY,
                                            width: 0, height: 0)
                popover.permittedArrowDirections = []
            }

            rootViewController.present(activityVC, animated: true)
        }
    }
}
