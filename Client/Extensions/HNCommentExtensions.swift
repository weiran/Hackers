//
//  HNCommentExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 08/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import HNScraper

public enum CommentVisibilityType: Int {
    case visible = 3
    case compact = 2
    case hidden = 1
}

extension HNComment: PropertyStoring {
    typealias T = CommentVisibilityType

    public var replyURL: URL? {
        if let url = URL(string: replyUrl) {
            return url
        } else {
            return nil
        }
    }

    private enum CustomProperties {
        static var commentVisibilityType: CommentVisibilityType = .visible
    }

    public var visibility: CommentVisibilityType {
        get {
            return getAssociatedObject(&CustomProperties.commentVisibilityType,
                                       defaultValue: CustomProperties.commentVisibilityType)
        }
        set {
            return objc_setAssociatedObject(self, &CustomProperties.commentVisibilityType,
                                            newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}

protocol PropertyStoring {
    associatedtype T
    func getAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T) -> T
}

extension PropertyStoring {
    func getAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T) -> T {
        guard let value = objc_getAssociatedObject(self, key) as? T else {
            return defaultValue
        }
        return value
    }
}
