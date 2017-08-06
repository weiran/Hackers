//
//  SettingsViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/08/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    let showThumbnailSetting = "showThumbnails"
    @IBOutlet weak var showThumbnailsSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let showThumbnails = UserDefaults.standard.bool(forKey: showThumbnailSetting)
        showThumbnailsSwitch.isOn = showThumbnails
    }

    @IBAction func showThumbnailsChanged(_ sender: Any) {
        let showThumbnails = showThumbnailsSwitch.isOn
        UserDefaults.standard.set(showThumbnails, forKey: showThumbnailSetting)
    }
    
}
