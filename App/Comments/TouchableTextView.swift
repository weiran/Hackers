//
//  TouchableTextView.swift
//  Hackers
//
//  Created by Weiran Zhang on 31/12/2017.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//
//  A UITextView that doesn't pass taps on links down the responder chain.

import UIKit

class TouchableTextView: UITextView {
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)

        delaysContentTouches = false
        isScrollEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        var location = point
        location.x -= textContainerInset.left
        location.y -= textContainerInset.top

        // find the character that's been tapped
        let characterIndex = layoutManager.characterIndex(
            for: location,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        if characterIndex < textStorage.length {
            // if the character is a link, handle the tap as UITextView normally would
            if textStorage.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) != nil {
                return self
            }
        }

        // otherwise return nil so the tap goes on to the next receiver
        return nil
    }
}
