//
//  AuthenticationBulletinPage.swift
//  Hackers
//
//  Created by Weiran Zhang on 27/05/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import BLTNBoard

class AuthenticationBulletinPage: BLTNPageItem {
    @objc var usernameTextField: UITextField!
    @objc var passwordTextField: UITextField!

    override func willDisplay() {
        usernameTextField.becomeFirstResponder()
    }

    override func makeViewsUnderDescription(with interfaceBuilder: BLTNInterfaceBuilder) -> [UIView]? {
        let usernameTextField = textField(with: AppTheme.default)
        usernameTextField.delegate = self
        usernameTextField.textContentType = .username
        usernameTextField.autocorrectionType = .no
        usernameTextField.autocapitalizationType = .none
        usernameTextField.returnKeyType = .next
        usernameTextField.attributedPlaceholder = themedAttributedString(
            for: "Username",
            color: AppTheme.default.lightTextColor
        )

        let passwordTextField = textField(with: AppTheme.default)
        passwordTextField.delegate = self
        passwordTextField.isSecureTextEntry = true
        passwordTextField.textContentType = .password
        passwordTextField.returnKeyType = .done
        passwordTextField.attributedPlaceholder = themedAttributedString(
            for: "Password",
            color: AppTheme.default.lightTextColor
        )

        self.usernameTextField = usernameTextField
        self.passwordTextField = passwordTextField

        return [usernameTextField, passwordTextField]
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
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        super.actionButtonTapped(sender: sender)
    }

    func set(state: CredentialsState) {
        switch state {
        case .standard:
            usernameTextField.backgroundColor = .clear
            passwordTextField.backgroundColor = .clear
        case .invalid:
            let errorColor = UIColor.red.withAlphaComponent(0.3)
            usernameTextField.backgroundColor = errorColor
            passwordTextField.backgroundColor = errorColor
        }
    }

    enum CredentialsState {
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
            set(state: .standard)
        } else {
            set(state: .invalid)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == self.passwordTextField {
            actionButtonTapped(sender: UIButton())
        }

        return true
    }
}
