//
//  ContentSharePresenter.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import LinkPresentation
import SwiftUI
import UIKit

public final class ContentSharePresenter: @unchecked Sendable {
    public static let shared = ContentSharePresenter()

    private init() {}

    @MainActor
    public func sharePost(_ post: Post) {
        showShareSheet(items: Self.items(for: post))
    }

    @MainActor
    public func shareURL(_ url: URL, title: String? = nil) {
        showShareSheet(items: Self.items(for: url, title: title))
    }

    @MainActor
    public func shareComment(_ comment: Comment) {
        showShareSheet(items: Self.items(for: comment))
    }

    @MainActor
    private func showShareSheet(items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let rootViewController = PresentationContextProvider.shared.rootViewController {
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

extension ContentSharePresenter {
    static func items(for post: Post) -> [Any] {
        items(for: post.url, title: post.title)
    }

    static func items(for url: URL, title: String? = nil) -> [Any] {
        [URLActivityItemSource(url: url, title: title)]
    }

    static func items(for comment: Comment) -> [Any] {
        [comment.text.strippingHTML()]
    }
}

final class URLActivityItemSource: NSObject, UIActivityItemSource {
    let url: URL
    private let title: String?

    init(url: URL, title: String?) {
        self.url = url
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_: UIActivityViewController) -> Any {
        return url
    }

    func activityViewController(
        _: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        if activityType == .copyToPasteboard {
            return url.absoluteString
        }

        return url
    }

    func activityViewController(
        _: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        if activityType == .copyToPasteboard {
            return ""
        }

        return title ?? ""
    }

    func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.url = url
        metadata.originalURL = url
        return metadata
    }
}
