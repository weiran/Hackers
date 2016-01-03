//
//  MainSplitViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/02/2015.
//  Copyright (c) 2015 Glass Umbrella. All rights reserved.
//

import UIKit

class MainSplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        preferredDisplayMode = .AllVisible
        
        HNManager.sharedManager().startSession()
    }
    
}
