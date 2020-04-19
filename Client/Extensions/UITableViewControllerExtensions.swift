//
//  BaseTableViewController.swift
//  Hackers
//
//  Created by Weiran Zhang on 21/04/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import UIKit

extension UITableViewController {
    public func smoothlyDeselectRows() {
        // Get the initially selected index paths, if any
        let selectedIndexPaths = tableView.indexPathsForSelectedRows ?? []

        // Grab the transition coordinator responsible for the current transition
        if let coordinator = transitionCoordinator {
            // Animate alongside the master view controller's view
            coordinator.animateAlongsideTransition(in: parent?.view, animation: { context in
                // Deselect the cells, with animations enabled if this is an animated transition
                selectedIndexPaths.forEach {
                    self.tableView.deselectRow(at: $0, animated: context.isAnimated)
                }
            }, completion: { context in
                // If the transition was cancel, reselect the rows that were selected before,
                // so they are still selected the next time the same animation is triggered
                if context.isCancelled {
                    selectedIndexPaths.forEach {
                        self.tableView.selectRow(at: $0, animated: false, scrollPosition: .none)
                    }
                }
            })
        } else { // If this isn't a transition coordinator, just deselect the rows without animating
            selectedIndexPaths.forEach {
                self.tableView.deselectRow(at: $0, animated: false)
            }
        }
    }
}
