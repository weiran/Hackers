//
//  UINavigationControllerExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit

extension UINavigationController: Themed {
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        navigationBar.setValue(true, forKey: "hidesShadow")
    }

    func applyTheme(_ theme: AppTheme) {
        navigationBar.tintColor = theme.appTintColor
        let titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: theme.titleTextColor
        ]
        navigationBar.titleTextAttributes = titleTextAttributes
        navigationBar.largeTitleTextAttributes = titleTextAttributes
        DispatchQueue.main.async {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
