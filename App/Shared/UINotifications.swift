//
//  UINotifications.swift
//  Hackers
//
//  Created by Weiran Zhang on 17/08/2022.
//  Copyright © 2022 Glass Umbrella. All rights reserved.
//

import Foundation
import Drops
import UIKit

enum UINotifications {
    static func showError() {
        let error = Drop(
            title: "Couldn't connect to Hacker News",
            icon: UIImage.init(systemName: "exclamationmark.circle.fill"),
            position: .bottom
        )

        Drops.show(error)
    }

    static func showSuccess(_ text: String) {
        let drop = Drop(
            title: text,
            icon: UIImage.init(systemName: "checkmark.circle.fill"),
            position: .bottom
        )

        Drops.show(drop)
    }
}
