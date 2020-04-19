//
//  SettingsTableViewCell.swift
//  Hackers
//
//  Created by Weiran Zhang on 05/05/2018.
//  Copyright © 2018 Glass Umbrella. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupTheming()
    }
}

extension SettingsTableViewCell: Themed {
    func applyTheme(_ theme: AppTheme) {
        titleLabel?.textColor = theme.titleTextColor
        textLabel?.textColor = theme.titleTextColor
        detailTextLabel?.textColor = theme.textColor
        backgroundColor = theme.groupedTableViewCellBackgroundColor
    }
}
