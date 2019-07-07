//
//  BounceExpansion.swift
//  Hackers
//
//  Created by Weiran Zhang on 15/06/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import SwipeCellKit

class BounceExpansion: SwipeExpanding {
    func animationTimingParameters(buttons: [UIButton], expanding: Bool) -> SwipeExpansionAnimationTimingParameters {
        return SwipeExpansionAnimationTimingParameters.default
    }

    func actionButton(_ button: UIButton, didChange expanding: Bool, otherActionButtons: [UIButton]) {
        if !expanding {
            BounceExpansion.animateScale(of: button, scale: 1)
        } else {
            BounceExpansion.animateScale(of: button, scale: 1.2, completionScale: 1.1)
        }
    }

    private static func animateScale(of view: UIView, scale: CGFloat, completionScale: CGFloat? = nil) {
        UIView.animate(withDuration: 0.1, animations: {
            view.transform = BounceExpansion.transform(for: scale)
        }, completion: { _ in
            if let completionScale = completionScale {
                UIView.animate(withDuration: 0.3) {
                    view.transform = BounceExpansion.transform(for: completionScale)
                }
            }
        })
    }

    private static func transform(for scale: CGFloat) -> CGAffineTransform {
        return scale == 1 ? CGAffineTransform.identity : CGAffineTransform(scaleX: scale, y: scale)
    }
}
