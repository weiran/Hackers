//
//  SFSafariViewController+PreviewActionItems.swift
//  Hackers
//
//  Created by Weiran Zhang on 30/04/2016.
//  Copyright © 2016 Glass Umbrella. All rights reserved.
//

import SafariServices
import ObjectiveC

private struct AssociatedKeys {
    static var PreviewActionItemsDelegateName = "previewActionItemsDelegate"
    static var InitialURL = "initialURL"
}

extension SFSafariViewController {
    private(set) public var initialURL: NSURL? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.InitialURL, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.InitialURL) as? NSURL
        }
    }
    
    public convenience init(initialURL: NSURL, entersReaderIfAvailable: Bool) {
        self.init(URL: initialURL, entersReaderIfAvailable: entersReaderIfAvailable)
        self.initialURL = initialURL
    }
}


// Preview action items
extension SFSafariViewController {
    weak var previewActionItemsDelegate: SFSafariViewControllerPreviewActionItemsDelegate? {
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.PreviewActionItemsDelegateName, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.PreviewActionItemsDelegateName) as? SFSafariViewControllerPreviewActionItemsDelegate
        }
    }
    
    public override func previewActionItems() -> [UIPreviewActionItem] {
        return previewActionItemsDelegate?.safariViewControllerPreviewActionItems(self) ?? []
    }
}

public protocol SFSafariViewControllerPreviewActionItemsDelegate: class {
    func safariViewControllerPreviewActionItems(controller: SFSafariViewController) -> [UIPreviewActionItem]
}