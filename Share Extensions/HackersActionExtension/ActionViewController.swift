//
//  ActionViewController.swift
//  HackersActionExtension
//
//  Created by Weiran Zhang on 04/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: OpenInViewController {
    @IBOutlet weak var infoLabel: UILabel!

    @IBAction func done() {
        close()
    }

    override func error() {
        infoLabel.isHidden = false
    }
}
