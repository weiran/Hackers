//
//  SFSafariViewController+PreviewActionItems.swift
//  Hackers
//
//  Created by Weiran Zhang on 30/04/2016.
//  Copyright © 2016 Weiran Zhang. All rights reserved.
//

import Foundation
import SafariServices
import ObjectiveC
import WebKit

private enum AssociatedKeys {
    static var PreviewActionItemsDelegateName = "previewActionItemsDelegate"
}

// Preview action items
extension SFSafariViewController {
    var previewActionItemsDelegate: SFSafariPreviewActionItemsDelegate? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.PreviewActionItemsDelegateName)
                as? SFSafariPreviewActionItemsDelegate
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.PreviewActionItemsDelegateName,
                                     newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }

    override open var previewActionItems: [UIPreviewActionItem] {
        return previewActionItemsDelegate?.safariViewControllerPreviewActionItems(self) ?? []
    }
}

protocol SFSafariPreviewActionItemsDelegate: AnyObject {
    func safariViewControllerPreviewActionItems(_ controller: SFSafariViewController) -> [UIPreviewActionItem]
}

extension SFSafariViewController {
    static func instance(
        for url: URL,
        previewActionItemsDelegate: SFSafariPreviewActionItemsDelegate? = nil
    ) -> SFSafariViewController? {
        if WKWebView.handlesURLScheme(url.scheme ?? "") == false {
            return nil
        }

        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = UserDefaults.standard.safariReaderModeEnabled

        let safariViewController = SFSafariViewController(url: url, configuration: configuration)
        safariViewController.previewActionItemsDelegate = previewActionItemsDelegate

        return safariViewController
    }
}
