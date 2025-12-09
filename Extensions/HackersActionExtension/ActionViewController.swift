//
//  ActionViewController.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import MobileCoreServices
import UIKit

class ActionViewController: OpenInViewController {
    @IBOutlet var infoLabel: UILabel!

    @IBAction func done() {
        close()
    }

    override func error() {
        Task { @MainActor in
            self.infoLabel.isHidden = false
        }
    }
}
