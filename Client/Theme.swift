//
//  Theme.swift
//  Hackers
//
//  Created by Weiran Zhang on 14/12/2015.
//  Copyright © 2015 Glass Umbrella. All rights reserved.
//

import Foundation
import UIKit

class Theme {
    static let purpleColour = UIColor(colorLiteralRed: 101/255.0, green: 19/255.0, blue: 229/255.0, alpha: 1)
    static let orangeColour = UIColor(colorLiteralRed: 223/255.0, green: 111/255.0, blue: 4/255.0, alpha: 1)
    static let backgroundGreyColour = UIColor(red:0.937, green:0.937, blue:0.956, alpha:1)
    static let backgroundOrangeColour = UIColor(red:0.783, green:0.701, blue:0.847, alpha:1)
    
    static private func setNavigationBarBackgroundGradient(navigationBar: UINavigationBar) {
        var frame = navigationBar.frame
        frame.size.height += 20 // include status bar
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = [purpleColour, orangeColour].map { $0.CGColor }
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        } else {
            gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        }
        
        // render the gradient to a UIImage
        UIGraphicsBeginImageContext(frame.size)
        gradientLayer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        navigationBar.setBackgroundImage(image, forBarMetrics: UIBarMetrics.Default)
    }
    
    static func setNavigationBarBackground(navigationBar: UINavigationBar) {
        setNavigationBarBackgroundGradient(navigationBar)
    }
}