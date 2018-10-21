//
//  HNPost+Extensions.swift
//  Hackers
//
//  Created by Robert Trencheny on 10/21/18.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import Foundation

extension HNPost {
    var LinkURL: URL {
        return URL(string: self.urlString)!
    }

    var CommentsURL: URL {
        return URL(string: "https://news.ycombinator.com/item?id=" + self.postId)!
    }

    var CommentsPageTitle: String {
        return self.title + " | Hacker News"
    }

    var CommentsActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.CommentsPageTitle,
                                                        self.CommentsURL], applicationActivities: nil)
    }

    var LinkActivityViewController: UIActivityViewController {
        return UIActivityViewController(activityItems: [self.title,
                                                        self.LinkURL], applicationActivities: nil)
    }
}
