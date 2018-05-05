//
//  ThemedSafariViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import SafariServices

class ThemedSafariViewController: SFSafariViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
    }
}

extension ThemedSafariViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        preferredBarTintColor = theme.barBackgroundColor
        preferredControlTintColor = theme.appTintColor
    }
}
