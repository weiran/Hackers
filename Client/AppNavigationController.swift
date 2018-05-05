//
//  AppNavigationController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit

class AppNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        navigationBar.setValue(true, forKey: "hidesShadow")
    }
}

extension AppNavigationController: Themed {
    func applyTheme(_ theme: AppTheme) {
        /// It's not ideal to use UIApplication.shared but overriding
        /// preferredStatusBarStyle doesn't work with a UITabBar
        UIApplication.shared.statusBarStyle = theme.statusBarStyle
        
        navigationBar.barTintColor = theme.barBackgroundColor
        navigationBar.tintColor = theme.barForegroundColor
        let titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: theme.titleTextColor
        ]
        navigationBar.titleTextAttributes = titleTextAttributes
        navigationBar.largeTitleTextAttributes = titleTextAttributes
    }
}
