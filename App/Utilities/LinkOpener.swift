//
//  LinkOpener.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import UIKit
import SafariServices

@MainActor
struct LinkOpener {
    static func openURL(_ url: URL, with post: Post? = nil, showCommentsButton: Bool = false) {
        guard !url.absoluteString.starts(with: "item?id=") else { return }

        if UserDefaults.standard.openInDefaultBrowser {
            // Open in system default browser
            UIApplication.shared.open(url)
        } else {
            // Open in internal Safari view controller
            if let svc = SFSafariViewController.instance(for: url) {
                PresentationService.shared.present(svc) {
                    if let post = post, showCommentsButton {
                        CommentsButton.attachTo(svc, with: post)
                    }
                }
            }
        }
    }
}