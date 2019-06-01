//
//  AppFont.swift
//  Hackers
//
//  Created by Weiran Zhang on 09/01/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import UIKit

public class AppFont {
    static public func commentUsernameFont(collapsed: Bool) -> UIFont {
        let fontFunc = collapsed ? scaledItalicFont : scaledFont
        return fontFunc(.subheadline, 15, .medium)
    }

    static public func commentDateFont(collapsed: Bool) -> UIFont {
        let fontFunc = collapsed ? scaledItalicFont : scaledFont
        return fontFunc(.subheadline, 15, .regular)
    }

    static private func scaledFont(for textStyle: UIFont.TextStyle, of size: CGFloat, with weight: UIFont.Weight) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        let scaledFont = fontMetrics.scaledFont(for: font)
        return scaledFont
    }

    static private func scaledItalicFont(for textStyle: UIFont.TextStyle, of size: CGFloat, with weight: UIFont.Weight) -> UIFont {
        let fontMetrics = UIFontMetrics(forTextStyle: textStyle)
        let font = UIFont.italicSystemFont(ofSize: size)
        let scaledFont = fontMetrics.scaledFont(for: font)
        return scaledFont
    }
}
