//
//  UINavigationControllerExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Weiran Zhang. All rights reserved.
//

import UIKit

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.setValue(true, forKey: "hidesShadow")
    }
}
