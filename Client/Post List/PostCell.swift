//
//  PostCell.swift
//  Hackers2
//
//  Created by Weiran Zhang on 07/06/2014.
//  Copyright (c) 2014 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class PostCell : UITableViewCell {
    @IBOutlet weak var postTitleView: PostTitleView!
    var backgroundLayer: CAGradientLayer?
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selected ? setSelectedBackground() : setUnselectedBackground()
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        highlighted ? setSelectedBackground() : setUnselectedBackground()
    }
    
    func setSelectedBackground() {
        backgroundColor = Theme.backgroundPurpleColour
    }
    
    func setUnselectedBackground() {
        backgroundColor = UIColor.clearColor()
    }
    
}