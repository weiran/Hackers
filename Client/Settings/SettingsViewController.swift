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

        PickerInlineRow<String>.defaultCellUpdate = { cell, row in
            let activeTheme = UserDefaults.standard.enabledTheme
            cell.textLabel?.textColor = activeTheme.textColor
            cell.detailTextLabel?.textColor = activeTheme.lightTextColor
            cell.backgroundColor = activeTheme.barBackgroundColor
            row.inlineRow?.cell.pickerTextAttributes = [.foregroundColor: activeTheme.titleTextColor]
        }

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
            }

            +++ PickerInlineRow<String>() {
                $0.title = "Open Links In"
                $0.options = ["In-app browser", "In-app browser (Reader mode)", "Safari", "Google Chrome"]
                $0.value = "In-app browser"
                $0.value = UserDefaults.standard.string(forKey: UserDefaultsKeys.OpenInBrowser.rawValue)
            }.onChange {
                if let rowVal = $0.value {
                    UserDefaults.standard.setOpenLinksIn(rowVal)
                }
        }
    }
    
    @IBAction func didPressDone(_ sender: Any) {
        dismiss(animated: true)
    }

    @objc func multipleSelectorDone(_ item:UIBarButtonItem) {
        _ = navigationController?.popViewController(animated: true)
    }
}

extension SettingsViewController: Themed {
    func applyTheme(_ theme: AppTheme) {
        view.backgroundColor = theme.barBackgroundColor
        tableView.backgroundColor = theme.barBackgroundColor
        tableView.separatorColor = theme.separatorColor
    }
}
