//
//  AuthenticationBulletinPage.swift
//  Hackers
//
//  Created by Weiran Zhang on 27/05/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import BLTNBoard

class AuthenticationBulletinPage: BLTNPageItem {
    @objc public var usernameTextField: UITextField!
    @objc public var passwordTextField: UITextField!
    
    override func willDisplay() {
        self.usernameTextField.becomeFirstResponder()
    }
    
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
