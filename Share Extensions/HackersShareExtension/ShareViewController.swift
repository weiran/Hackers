//
//  ShareViewController.swift
//  HackersShareExtension
//
//  Created by Weiran Zhang on 02/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit
import Social

class ShareViewController: OpenInViewController {
    @IBOutlet weak var infoLabel: UILabel!

    @IBAction func done() {
        close()
    }

    override func error() {
        infoLabel.isHidden = false
    }
}
