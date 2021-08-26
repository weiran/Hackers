//
//  CommentDelegate.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/09/2014.
//  Copyright (c) 2014 Weiran Zhang. All rights reserved.
//

import UIKit

protocol CommentDelegate: AnyObject {
    func commentTapped(_ sender: UITableViewCell)
    func linkTapped(_ url: URL, sender: UITextView)
    func internalLinkTapped(postId: Int, url: URL, sender: UITextView)
}
