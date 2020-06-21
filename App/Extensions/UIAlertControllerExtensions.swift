//
//  UIAlertControllerExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 02/05/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit

extension UIAlertController: Themed {
    convenience init(title: String?, message: String?, preferredStyle: UIAlertController.Style, themed: Bool) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        if themed {
            setupTheming()
        }
    }

    func applyTheme(_ theme: AppTheme) {
        overrideUserInterfaceStyle = theme.userInterfaceStyle
        view.tintColor = theme.appTintColor
    }
}
