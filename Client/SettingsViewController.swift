//
//  SettingsViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/08/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    var settingsModel: SettingsModel!
    
    @IBOutlet weak var hideThumbnailsSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideThumbnailsSwitch.isOn = SettingsModel.shared.hideThumbnails
        navigationItem.largeTitleDisplayMode = .always
    }

    @IBAction func showThumbnailsChanged(_ sender: Any) {
        SettingsModel.shared.hideThumbnails = hideThumbnailsSwitch.isOn
    }
    
    @IBAction func didPressDone(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
