//
//  MainTabBarController.swift
//  Hackers
//
//  Created by Weiran Zhang on 10/09/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import UIKit
import libHN

class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let viewControllers = self.viewControllers else { return }
        for (index, viewController) in viewControllers.enumerated() {
            if let newsVC = viewController as? NewsViewController {
                var postType: PostFilterType?
                var typeName: String?
                var iconName: String?
                switch index {
                case 1:
                    postType = .ask
                    typeName = "Ask"
                    iconName = "AskIcon"
                    break
                case 2:
                    postType = .jobs
                    typeName = "Jobs"
                    iconName = "JobsIcon"
                    break
                case 3:
                    postType = .new
                    typeName = "New"
                    iconName = "NewIcon"
                    break
                case 0:
                    fallthrough
                default:
                    postType = .top
                    typeName = "Top"
                    iconName = "TopIcon"
                }
                newsVC.postType = postType
                newsVC.tabBarItem.title = typeName
                newsVC.tabBarItem.image = UIImage(named: iconName!)
            }
        }
    }
}
