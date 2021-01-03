//
//  TitleButton.swift
//  Hackers
//
//  Created by Weiran Zhang on 06/07/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit

class TitleButton: UIButton {
    private var titleText: String?
    var handler: ((PostType) -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()
        setupTheming()
        setupMenu()
    }

    func setTitleText(_ text: String) {
        titleText = text

        let symbolConfig = UIImage.SymbolConfiguration(
            pointSize: 10,
            weight: .black,
            scale: .small
        )

        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(
            systemName: "chevron.down",
            withConfiguration: symbolConfig
        )?.withTintColor(
            AppThemeProvider.shared.currentTheme.titleTextColor
        ).withBaselineOffset(
            fromBottom: -UIFont.systemFontSize / 4
        )

        let attributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)]
        let attributedString = NSMutableAttributedString(string: "\(text) ", attributes: attributes)
        attributedString.append(NSAttributedString(attachment: imageAttachment))

        self.setAttributedTitle(attributedString, for: .normal)
    }

    func setupMenu() {
        self.showsMenuAsPrimaryAction = true

        let actions = PostType.allCases.map { postType -> UIAction in
            let action = UIAction(
                title: postType.title,
                identifier: UIAction.Identifier(postType.rawValue),
                handler: handleAction(sender:)
            )
            action.image = UIImage(systemName: postType.iconName)
            return action
        }

        let menu = UIMenu(title: "", children: actions)
        self.menu = menu
    }

    @objc private func handleAction(sender: UIAction) {
        if let handler = handler,
           let postType = PostType(rawValue: sender.identifier.rawValue) {
            handler(postType)
        }
    }
}

extension TitleButton: Themed {
    func applyTheme(_ theme: AppTheme) {
        overrideUserInterfaceStyle = theme.userInterfaceStyle
    }
}
