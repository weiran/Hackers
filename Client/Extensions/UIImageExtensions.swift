//
//  UIImage+Extensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 14/04/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import UIKit

extension UIImage {
    public func withTint(color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.setFill()

        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(CGBlendMode.normal)

        let rect = CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height))
        context.clip(to: rect, mask: cgImage!)
        context.fill(rect)

        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        UIGraphicsEndImageContext()

        return newImage
    }
}
