//
//  UIAlertControllerExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 02/05/2020.
//  Copyright © 2020 Glass Umbrella. All rights reserved.
//

import UIKit

extension UIAlertController: Themed {
    func applyTheme(_ theme: AppTheme) {
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
