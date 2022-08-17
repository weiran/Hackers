//
//  UINotifications.swift
//  Hackers
//
//  Created by Weiran Zhang on 17/08/2022.
//  Copyright © 2022 Glass Umbrella. All rights reserved.
//

import Foundation
import Drops

struct UINotifications {
    static func showError() {
        let drops = Drops()
        drops.show(Drop(title: "Couldn't connect to Hacker News"))
    }
}
