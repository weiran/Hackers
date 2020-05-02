//
//  UIActivityViewControllerExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 02/05/2020.
//  Copyright © 2020 Glass Umbrella. All rights reserved.
//

import UIKit

extension UIActivityViewController: Themed {
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
    }

    func applyTheme(_ theme: AppTheme) {
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
