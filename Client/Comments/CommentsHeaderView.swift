//
//  CommentsHeaderView.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit

class CommentsHeaderView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTheming()
    }
}

extension CommentsHeaderView: Themed {
    func applyTheme(_ theme: AppTheme) {
        backgroundColor = theme.backgroundColor
        titleLabel.textColor = theme.titleTextColor
        separatorView.backgroundColor = theme.separatorColor
    }
}
