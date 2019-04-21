//
//  BaseTableViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 21/04/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import UIKit

class BaseTableViewController: UITableViewController {
    // resize visible table view cells on rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        DispatchQueue.global().async(execute: {
            DispatchQueue.main.sync {
                guard let tableView = self.tableView, let indexPaths = tableView.indexPathsForVisibleRows else { return }
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: indexPaths, with: .automatic)
                self.tableView.endUpdates()
            }
        })
    }
}
