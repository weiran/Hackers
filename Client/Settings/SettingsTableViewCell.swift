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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selected ? setSelectedBackground() : setUnselectedBackground()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        highlighted ? setSelectedBackground() : setUnselectedBackground()
    }

    private func setSelectedBackground() {
        backgroundColor = AppThemeProvider.shared.currentTheme.cellHighlightColor
    }

    private func setUnselectedBackground() {
        backgroundColor = AppThemeProvider.shared.currentTheme.groupedTableViewCellBackgroundColor
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
