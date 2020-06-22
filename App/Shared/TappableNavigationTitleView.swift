//
//  TappableNavigationTitleView.swift
//  Hackers
//
//  Created by Weiran Zhang on 15/06/2020.
//  Copyright © 2020 Weiran Zhang. All rights reserved.
//

import UIKit

class TappableNavigationTitleView: UILabel {
    private var titleText: String?

    override func layoutSubviews() {
        super.layoutSubviews()
        setupTheming()
    }

    func setTitleText(_ text: String) {
        titleText = text

        let symbolConfig = UIImage.SymbolConfiguration(
            pointSize: 10,
            weight: .regular,
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

        attributedText = attributedString
    }

    private func updateTitleText() {
        if let titleText = titleText {
            setTitleText(titleText)
        }
    }
}

extension TappableNavigationTitleView: Themed {
    func applyTheme(_ theme: AppTheme) {
    }
}
