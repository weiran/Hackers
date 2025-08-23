//
//  ActionViewController.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import UIKit
import MobileCoreServices

class ActionViewController: OpenInViewController {
    @IBOutlet weak var infoLabel: UILabel!

    @IBAction func done() {
        close()
    }

    override func error() {
        DispatchQueue.main.async {
            self.infoLabel.isHidden = false
        }
    }
}
