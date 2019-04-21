//
//  ThemedSafariViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import SafariServices

extension SFSafariViewController: Themed {
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
    }
    
    func applyTheme(_ theme: AppTheme) {
        preferredBarTintColor = theme.barBackgroundColor
        preferredControlTintColor = theme.appTintColor
        view.backgroundColor = theme.backgroundColor
    }
}
