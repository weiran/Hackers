//
//  SettingsViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    @IBOutlet weak var jobsSwitch: UISwitch!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()
        darkModeSwitch.isOn = UserDefaults.standard.darkModeEnabled
        jobsSwitch.setOn(UserDefaults.standard.jobsEnabled, animated: false)
    }
    
    @IBAction func darkModeValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.setDarkMode(sender.isOn)
        AppThemeProvider.shared.currentTheme = sender.isOn ? .dark : .light
    }
    
    @IBAction func jobsValueChanged(_ sender: UISwitch) {
        UserDefaults.standard.setJobsEnabled(sender.isOn)
    }

    @IBAction func didPressDone(_ sender: Any) {
        dismiss(animated: true)
    }
}

extension SettingsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.barBackgroundColor
        tableView.backgroundColor = theme.barBackgroundColor
        tableView.separatorColor = theme.separatorColor
    }
}
