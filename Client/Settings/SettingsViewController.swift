//
//  SettingsViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit
import PromiseKit
import HNScraper
import Loaf

class SettingsViewController: UITableViewController {
    public var sessionService: SessionService?
    
    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var safariReaderModeSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        darkModeSwitch.isOn = UserDefaults.standard.darkModeEnabled
        safariReaderModeSwitch.isOn = UserDefaults.standard.safariReaderModeEnabled
        if self.sessionService!.authenticationState == .authenticated {
            self.usernameLabel.text = self.sessionService?.username
        }
    }
    
    @IBAction private func darkModeValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.setDarkMode(sender.isOn)
        AppThemeProvider.shared.currentTheme = sender.isOn ? .dark : .light
    }
    
    @IBAction func safariReaderModelValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.setSafariReaderMode(sender.isOn)
    }
    
    @IBAction private func didPressDone(_ sender: Any) {
        dismiss(animated: true)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        // override with empty implementation to prevent the extension running which reloads tableview data
    }
}

extension SettingsViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            self.showLogin()
            break
            
        default: break
        }
    }
    
    private func showLogin() {
        let loginController = UIAlertController(title: "Login to Hacker News", message: "Your Hacker News credentials are stored securely on your device only.", preferredStyle: .alert)
        let loginAction = UIAlertAction(title: "Login", style: .default) { action in
            guard let username = loginController.textFields?[0].text, let password = loginController.textFields?[1].text else {
                return
            }
            firstly {
                self.sessionService!.authenticate(username: username, password: password)
            }.done { authenticationState in
                guard authenticationState == .authenticated else { return }
                self.usernameLabel.text = self.sessionService!.username
                Loaf("Logged in as \(username)", state: .success, sender: self).show()
            }.ensure {
                guard let indexPath = self.tableView.indexPathForSelectedRow else { return }
                self.tableView.deselectRow(at: indexPath, animated: true)
            }.catch { error in
                switch error as! HNLogin.HNLoginError {
                case .badCredentials:
                    let badCredentialsAlert = UIAlertController(title: "Login to Hacker News", message: "Your username or password was incorrect.", preferredStyle: .alert)
                    badCredentialsAlert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { action in
                        self.showLogin()
                    }))
                    badCredentialsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    self.present(badCredentialsAlert, animated: true)
                default:
                    Loaf("Error connecting to Hacker News", state: .error, sender: self).show()
                    break
                }
            }
        }
        loginController.addAction(loginAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        loginController.addAction(cancelAction)
        loginController.addTextField { textField in
            textField.placeholder = "Username"
            textField.autocorrectionType = .no
        }
        loginController.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        self.present(loginController, animated: true)
    }
}

extension SettingsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.barBackgroundColor
        tableView.backgroundColor = theme.barBackgroundColor
        tableView.separatorColor = theme.separatorColor
    }
}
