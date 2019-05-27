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
    
    var bulletinManager: BLTNItemManager?
    
    public func showAuthentication() {
        let manager = BLTNItemManager(rootItem: loginPage())
        let theme = AppThemeProvider.shared.currentTheme
        manager.backgroundColor = theme.barBackgroundColor
        self.bulletinManager = manager
        self.bulletinManager?.showBulletin(in: UIApplication.shared)
    }
    
    private func displayActivityIndicator() {
        guard let bulletinManager = self.bulletinManager else { return }
        let theme = AppThemeProvider.shared.currentTheme
        bulletinManager.displayActivityIndicator(color: theme.textColor)
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
                self.displayActivityIndicator()
            
                self.sessionService.authenticate(username: item.usernameTextField.text!, password: item.passwordTextField.text!)
                .done { authenticationState in
                    page.next = self.loginSuccessPage()
                    item.manager?.displayNextItem()
                }.ensure {
                    self.sendAuthenticationDidChangeNotification()
                }.catch { error in
                    item.set(state: .invalid)
                    self.bulletinManager?.hideActivityIndicator()
                }
            }
        }
        
        page.alternativeHandler = { item in
            self.hackerNewsService.logout()
            self.sendAuthenticationDidChangeNotification()
            item.manager?.dismissBulletin()
        }
        
        themeAppearance(of: page)
        
        return page
    }
    
    private func loginSuccessPage() -> BLTNPageItem {
        let page = BLTNPageItem(title: "Logged In")
        let username = self.sessionService.username!
        page.descriptionText = "Successfully logged in as \(username)"
        page.image = UIImage(named: "SuccessIcon")?.withRenderingMode(.alwaysTemplate)
        page.appearance.imageViewTintColor = #colorLiteral(red: 0.2980392157, green: 0.8509803922, blue: 0.3921568627, alpha: 1)
        page.isDismissable = true
        page.actionButtonTitle = "Dismiss"
        page.actionHandler = { item in
            item.manager?.dismissBulletin()
        }
        themeAppearance(of: page)
        
        return page
    }
    
    private func themeAppearance(of item: BLTNPageItem) {
        let theme = AppThemeProvider.shared.currentTheme
        item.appearance.actionButtonColor = theme.appTintColor
        item.appearance.alternativeButtonTitleColor = theme.appTintColor
        item.appearance.titleTextColor = theme.titleTextColor
        item.appearance.descriptionTextColor = theme.textColor
    }
    
    struct Notifications {
        static let AuthenticationDidChangeNotification = NSNotification.Name(rawValue: "AuthenticationDidChangeNotification")
    }
    
    private func sendAuthenticationDidChangeNotification() {
        NotificationCenter.default.post(name: Notifications.AuthenticationDidChangeNotification, object: nil)
    }
}

class AuthenticationBulletinPage: BLTNPageItem {
    @objc public var usernameTextField: UITextField!
    @objc public var passwordTextField: UITextField!
    
    override func makeViewsUnderDescription(with interfaceBuilder: BLTNInterfaceBuilder) -> [UIView]? {
        let theme = AppThemeProvider.shared.currentTheme
        
        let usernameTextField = textField(with: theme)
        usernameTextField.delegate = self
        usernameTextField.textContentType = .username
        usernameTextField.autocorrectionType = .no
        usernameTextField.autocapitalizationType = .none
        usernameTextField.returnKeyType = .next
        usernameTextField.attributedPlaceholder = themedAttributedString(for: "Username", color: theme.lightTextColor)
        
        let passwordTextField = textField(with: theme)
        passwordTextField.delegate = self
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        passwordTextField.returnKeyType = .done
        passwordTextField.attributedPlaceholder = themedAttributedString(for: "Password", color: theme.lightTextColor)
        
        self.usernameTextField = usernameTextField
        self.passwordTextField = passwordTextField
        
        return [self.usernameTextField, self.passwordTextField]
    }
    
    private func themedAttributedString(for string: String, color: UIColor) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.foregroundColor: color]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    private func textField(with theme: AppTheme) -> UITextField {
        let textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.backgroundColor = theme.backgroundColor
        textField.textColor = theme.textColor
        textField.layer.borderColor = theme.separatorColor.cgColor
        textField.layer.borderWidth = 1.0
        textField.layer.cornerRadius = 8
        textField.layer.masksToBounds = true
        return textField
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.usernameTextField {
            self.passwordTextField.becomeFirstResponder()
        } else if textField == self.passwordTextField {
            self.actionButtonTapped(sender: UIButton())
        }
        
        return true
    }
}
