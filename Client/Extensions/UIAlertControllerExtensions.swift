//
//  UIAlertControllerExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 02/05/2020.
//  Copyright © 2020 Glass Umbrella. All rights reserved.
//

import UIKit

extension UIAlertController: Themed {
    public convenience init(title: String?, message: String?, preferredStyle: UIAlertController.Style, themed: Bool) {
        self.init(title: title, message: message, preferredStyle: preferredStyle)
        setupTheming()
    }

    func applyTheme(_ theme: AppTheme) {
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
