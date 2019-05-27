//
//  AuthenticationUIService.swift
//  Hackers
//
//  Created by Weiran Zhang on 27/05/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import UIKit
import BLTNBoard
import PromiseKit

class AuthenticationUIService {
    private let hackerNewsService: HackerNewsService
    private let sessionService: SessionService
    
    public init(hackerNewsService: HackerNewsService, sessionService: SessionService) {
        self.hackerNewsService = hackerNewsService
        self.sessionService = sessionService
    }
    
    lazy var bulletinManager: BLTNItemManager = {
        return BLTNItemManager(rootItem: loginPage())
    }()
    
    public func showAuthentication() {
        self.bulletinManager.showBulletin(in: UIApplication.shared)
    }
    
    private func loginPage() -> AuthenticationBulletinPage {
        let page = AuthenticationBulletinPage(title: "Login")
        page.descriptionText = "Hackers never stores your password."
        page.actionButtonTitle = "Login"
        if self.sessionService.authenticationState == .authenticated {
            page.alternativeButtonTitle = "Logout"
        }
        page.isDismissable = true
        
        page.actionHandler = { item in
            guard let item = item as? AuthenticationBulletinPage else { return }
            
            if item.usernameTextField.text!.isEmpty || item.passwordTextField.text!.isEmpty {
                item.set(state: .invalid)
            } else {
                self.bulletinManager.displayActivityIndicator()
            
                self.sessionService.authenticate(username: item.usernameTextField.text!, password: item.passwordTextField.text!)
                .done { authenticationState in
                    page.next = self.loginSuccessPage()
                    item.manager?.displayNextItem()
                }.catch { error in
                    item.set(state: .invalid)
                    self.bulletinManager.hideActivityIndicator()
                }
            }
        }
        
        page.alternativeHandler = { item in
            self.hackerNewsService.logout()
            item.manager?.dismissBulletin()
        }
        
        return page
    }
    
    private func loginSuccessPage() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Logged In")
        let username = self.sessionService.username!
        page.descriptionText = "Successfully logged in as \(username)"
        page.image = UIImage(named: "SuccessIcon")?.withRenderingMode(.alwaysTemplate)
        page.isDismissable = true
        page.actionButtonTitle = "Dismiss"
        page.actionHandler = { item in
            item.manager?.dismissBulletin()
        }
        
        return page
    }
}

class AuthenticationBulletinPage: BLTNPageItem {
    @objc public var usernameTextField: UITextField!
    @objc public var passwordTextField: UITextField!
    
    override func makeViewsUnderDescription(with interfaceBuilder: BLTNInterfaceBuilder) -> [UIView]? {
        let usernameTextField = interfaceBuilder.makeTextField(placeholder: "Username", returnKey: .next, delegate: self)
        usernameTextField.textContentType = .username
        usernameTextField.autocorrectionType = .no
        usernameTextField.autocapitalizationType = .none
        
        
        let passwordTextField = interfaceBuilder.makeTextField(placeholder: "Password", returnKey: .go, delegate: self)
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        
        self.usernameTextField = usernameTextField
        self.passwordTextField = passwordTextField
        
        return [self.usernameTextField, self.passwordTextField]
    }
    
    override func actionButtonTapped(sender: UIButton) {
        self.usernameTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        super.actionButtonTapped(sender: sender)
    }
    
    public func set(state: CredentialsState) {
        switch state {
        case .standard:
            self.usernameTextField.backgroundColor = .clear
            self.passwordTextField.backgroundColor = .clear
        case .invalid:
            let errorColor = UIColor.red.withAlphaComponent(0.3)
            self.usernameTextField.backgroundColor = errorColor
            self.passwordTextField.backgroundColor = errorColor
        }
    }
    
    public enum CredentialsState {
        case standard
        case invalid
    }
}

extension AuthenticationBulletinPage: UITextFieldDelegate {
    @objc open func isInputValid(text: String?) -> Bool {
        if text == nil || text!.isEmpty {
            return false
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if isInputValid(text: textField.text) {
            self.set(state: .standard)
        } else {
            self.set(state: .invalid)
        }
    }
}
