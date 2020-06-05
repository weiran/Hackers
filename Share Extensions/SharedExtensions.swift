//
//  SharedExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit

enum SharedExtensions {
    public static func open(_ url: URL, in object: Any) {
        var responder: UIResponder? = object as? UIResponder
        while let res = responder {
            // can't reference openURL: with #selector due to it
            // being unavailble in extensions
            if res.responds(to: "openURL:") {
                res.perform("openURL:", with: url)
                break
            }
            responder = res.next
        }
    }
}
