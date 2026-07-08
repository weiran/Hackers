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
    public func shareHackerNewsPost(_ post: Post) {
        let url = post.hackerNewsURL
        showShareSheet(
            items: Self.items(for: url, title: post.title),
            applicationActivities: Self.hackerNewsPostActivities(for: url),
            excludedActivityTypes: [.copyToPasteboard]
        )
    }

    @MainActor
    public func shareComment(_ comment: Comment) {
        showShareSheet(items: Self.items(for: comment))
    }

    @MainActor
    private func showShareSheet(
        items: [Any],
        applicationActivities: [UIActivity]? = nil,
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
        activityVC.excludedActivityTypes = excludedActivityTypes

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
        [CommentHTMLParser.plainText(fromHTML: comment.text)]
    }

    static func hackerNewsPostActivities(for url: URL) -> [UIActivity] {
        [
            OpenInSafariActivity(url: url) { UIApplication.shared.open($0) },
            CopyLinkActivity(url: url) { UIPasteboard.general.string = $0.absoluteString }
        ]
    }
}

final class OpenInSafariActivity: UIActivity {
    private let url: URL
    private let opener: (URL) -> Void

    init(url: URL, opener: @escaping (URL) -> Void) {
        self.url = url
        self.opener = opener
        super.init()
    }

    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType("com.weiranzhang.Hackers.openInSafari")
    }

    override var activityTitle: String? {
        "Open in Safari"
    }

    override var activityImage: UIImage? {
        UIImage(systemName: "safari")
    }

    override class var activityCategory: UIActivity.Category {
        .action
    }

    override func canPerform(withActivityItems _: [Any]) -> Bool {
        url.scheme == "http" || url.scheme == "https"
    }

    override func perform() {
        opener(url)
        activityDidFinish(true)
    }
}

final class CopyLinkActivity: UIActivity {
    private let url: URL
    private let copier: (URL) -> Void

    init(url: URL, copier: @escaping (URL) -> Void) {
        self.url = url
        self.copier = copier
        super.init()
    }

    override var activityType: UIActivity.ActivityType? {
        UIActivity.ActivityType("com.weiranzhang.Hackers.copyLink")
    }

    override var activityTitle: String? {
        "Copy Link"
    }

    override var activityImage: UIImage? {
        UIImage(systemName: "doc.on.doc")
    }

    override class var activityCategory: UIActivity.Category {
        .action
    }

    override func canPerform(withActivityItems _: [Any]) -> Bool {
        url.scheme == "http" || url.scheme == "https"
    }

    override func perform() {
        copier(url)
        activityDidFinish(true)
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
