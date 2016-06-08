//
//  UIViewControllerSmoothlyDeselectCellExtension.swift
//  Hackers
//
//  Created by Weiran Zhang on 08/06/2016.
//  Copyright © 2016 Glass Umbrella. All rights reserved.
//

extension UIViewController {
    func rz_smoothlyDeselectRows(tableView tableView: UITableView?) {
        // Get the initially selected index paths, if any
        let selectedIndexPaths = tableView?.indexPathsForSelectedRows ?? []
        
        // Grab the transition coordinator responsible for the current transition
        if let coordinator = transitionCoordinator() {
            // Animate alongside the master view controller's view
            coordinator.animateAlongsideTransitionInView(parentViewController?.view, animation: { context in
                // Deselect the cells, with animations enabled if this is an animated transition
                selectedIndexPaths.forEach {
                    tableView?.deselectRowAtIndexPath($0, animated: context.isAnimated())
                }
                }, completion: { context in
                    // If the transition was cancel, reselect the rows that were selected before,
                    // so they are still selected the next time the same animation is triggered
                    if context.isCancelled() {
                        selectedIndexPaths.forEach {
                            tableView?.selectRowAtIndexPath($0, animated: false, scrollPosition: .None)
                        }
                    }
            })
        }
        else { // If this isn't a transition coordinator, just deselect the rows without animating
            selectedIndexPaths.forEach {
                tableView?.deselectRowAtIndexPath($0, animated: false)
            }
        }
    }
}