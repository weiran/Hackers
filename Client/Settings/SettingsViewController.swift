//
//  SettingsViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit
import Eureka

class SettingsViewController: FormViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTheming()

        form
            +++ PickerInlineRow<String>("theme") {
                $0.title = "Theme"
                $0.options = ["Light", "Dark", "Black", "Original"]
                $0.value = UserDefaults.standard.enabledTheme.description
            }.onChange {
                if let rowVal = $0.value {
                    UserDefaults.standard.setTheme(rowVal)
                    AppThemeProvider.shared.currentTheme = UserDefaults.standard.enabledTheme
                }
            }.cellUpdate { cell, row in
                let activeTheme = UserDefaults.standard.enabledTheme
                cell.textLabel?.textColor = activeTheme.textColor
                cell.detailTextLabel?.textColor = activeTheme.lightTextColor
                cell.backgroundColor = activeTheme.barBackgroundColor
                row.inlineRow?.cell.pickerTextAttributes = [.foregroundColor: activeTheme.titleTextColor]
            }
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
