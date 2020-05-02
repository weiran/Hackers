//
//  EmptyViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 10/09/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import UIKit

class EmptyViewController: UIViewController {
    @IBOutlet weak var descriptionLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
    }
}

extension EmptyViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.backgroundColor
        descriptionLabel.textColor = theme.titleTextColor
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
