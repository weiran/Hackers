//
//  MainSplitViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/02/2015.
//  Copyright (c) 2015 Weiran Zhang. All rights reserved.
//

import UIKit

class MainSplitViewController: UISplitViewController {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupTheming()
    }
}

extension MainSplitViewController: Themed {
    // Using the MainSplitViewController as a place to handle global theme changes
    open func applyTheme(_ theme: AppTheme) {
        UITextView.appearance().tintColor = theme.appTintColor
        UITabBar.appearance().tintColor = theme.appTintColor
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
