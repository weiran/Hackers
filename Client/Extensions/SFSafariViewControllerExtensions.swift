//
//  SFSafariViewController+PreviewActionItems.swift
//  Hackers
//
//  Created by Weiran Zhang on 30/04/2016.
//  Copyright © 2016 Glass Umbrella. All rights reserved.
//

import Foundation
import SafariServices
import ObjectiveC
import WebKit

private enum AssociatedKeys {
    static var PreviewActionItemsDelegateName = "previewActionItemsDelegate"
    static var InitialURL = "initialURL"
}

extension SFSafariViewController {
    public private(set) var initialURL: URL? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.InitialURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.InitialURL) as? URL
        }
    }

    public convenience init(initialURL: URL) {
        self.init(url: initialURL)
        self.initialURL = initialURL
    }
}

// Preview action items
extension SFSafariViewController {
    var previewActionItemsDelegate: SFSafariViewControllerPreviewActionItemsDelegate? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.PreviewActionItemsDelegateName,
                                     newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.PreviewActionItemsDelegateName)
                as? SFSafariViewControllerPreviewActionItemsDelegate
        }
    }

    override open var previewActionItems: [UIPreviewActionItem] {
        return previewActionItemsDelegate?.safariViewControllerPreviewActionItems(self) ?? []
    }
}

public protocol SFSafariViewControllerPreviewActionItemsDelegate: class {
    func safariViewControllerPreviewActionItems(_ controller: SFSafariViewController) -> [UIPreviewActionItem]
}

// Theming
extension SFSafariViewController: Themed {
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
    }

    func applyTheme(_ theme: AppTheme) {
        overrideUserInterfaceStyle = theme.userInterfaceStyle
        preferredControlTintColor = theme.appTintColor
        preferredBarTintColor = theme.backgroundColor
        view.backgroundColor = theme.backgroundColor
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}

extension SFSafariViewController {
    public static func instance(for url: URL,
                                previewActionItemsDelegate: SFSafariViewControllerPreviewActionItemsDelegate? = nil)
        -> SFSafariViewController? {
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
