//
//  UIViewControllerExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 23/10/2020.
//  Copyright © 2020 Glass Umbrella. All rights reserved.
//

import UIKit

extension UIViewController {
    func openURL(url: URL, safariViewControllerAction: () -> Void) {
         if UserDefaults.standard.openInDefaultBrowser {
             UIApplication.shared.open(url)
         } else {
             safariViewControllerAction()
         }
     }
}
