//
//  ThemedSafariViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import SafariServices

public class ThemedSafariViewController: SFSafariViewController {
    var onDoneBlock : ((Bool) -> Void)?

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if let block = onDoneBlock {
            block(true)
        }
    }
}

extension ThemedSafariViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        preferredBarTintColor = theme.barBackgroundColor
        preferredControlTintColor = theme.appTintColor
        view.backgroundColor = theme.backgroundColor
    }
}
