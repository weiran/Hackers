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
    public var authenticationUIService: AuthenticationUIService?

    @IBOutlet weak var accountLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    @IBOutlet weak var safariReaderModeSwitch: UISwitch!

    private var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        darkModeSwitch.isOn = UserDefaults.standard.darkModeEnabled
        safariReaderModeSwitch.isOn = UserDefaults.standard.safariReaderModeEnabled
        updateUsername()
        notificationToken = NotificationCenter.default
            .observe(name: AuthenticationUIService.Notifications.AuthenticationDidChangeNotification,
                     object: nil, queue: .main) { _ in self.updateUsername() }
    }

    private func updateUsername() {
        if sessionService?.authenticationState == .authenticated {
            usernameLabel.text = sessionService?.username
        } else {
            usernameLabel.text = "Not logged in"
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
            // login
            authenticationUIService?.showAuthentication()
        case (3, 0):
            // what's new
            if let viewController = OnboardingService.onboardingViewController(forceShow: true) {
                present(viewController, animated: true)
            }
        default: break
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}

extension SettingsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.groupedTableViewBackgroundColor
    }
}
