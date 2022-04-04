//
//  AuthenticationHelper.swift
//  Hackers
//
//  Created by Weiran Zhang on 04/04/2022.
//  Copyright © 2022 Weiran Zhang. All rights reserved.
//

import UIKit
import SwiftUI

enum AuthenticationHelper {
    static func showLoginView(_ presentingViewController: UIViewController) {
        let loginView = UIHostingController(rootView: LoginView())
        presentingViewController.present(loginView, animated: true)
    }

    static func unauthenticatedAlertController(_ presentingViewController: UIViewController) -> UIAlertController {
        let unauthenticatedMessage = "You're not logged into Hacker News. Do you want to login now?"
        let authenticationAlert = UIAlertController(
            title: "Not logged in",
            message: unauthenticatedMessage,
            preferredStyle: .alert
        )
        authenticationAlert.addAction(UIAlertAction(title: "Not Now", style: .cancel, handler: nil))
        authenticationAlert.addAction(UIAlertAction(title: "Login", style: .default, handler: { _ in
            self.showLoginView(presentingViewController)
        }))
        return authenticationAlert
    }
}
