//
//  NavigationAlertController.swift
//  Hackers
//
//  Created by Weiran Zhang on 20/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit

class NavigationAlertController: UIAlertController {
    private var handler: ((_ postType: PostType) -> Void)?

    func setup(handler: @escaping (_ postType: PostType) -> Void) {
        setupTheming()
        setupActions()
        self.handler = handler
    }

    private func setupActions() {
        PostType.allCases.forEach { postType in
            let action = UIAlertAction(
                title: postType.title,
                style: .default,
                handler: actionHandler(action:)
            )
            action.setValue(UIImage(systemName: postType.iconName), forKey: "image")
            action.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            self.addAction(action)
        }

        self.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: nil
        ))
    }

    private func actionHandler(action: UIAlertAction) {
        if let handler = handler, let index = actions.firstIndex(of: action) {
            let postType = PostType.allCases[index]
            handler(postType)
        }
    }
}
