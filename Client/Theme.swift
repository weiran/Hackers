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
    static let purpleColour = UIColor(red: 101/255.0, green: 19/255.0, blue: 229/255.0, alpha: 1)
    static let orangeColour = UIColor(red: 223/255.0, green: 111/255.0, blue: 4/255.0, alpha: 1)
    static let backgroundGreyColour = UIColor(red:0.937, green:0.937, blue:0.956, alpha:1)
    static let backgroundOrangeColour = UIColor(red:1, green:0.849, blue:0.684, alpha:1)
    static let backgroundPurpleColour = UIColor(red:0.879, green:0.816, blue:0.951, alpha:1)
    
    static fileprivate func setNavigationBarBackgroundGradient(_ navigationBar: UINavigationBar?) {
        guard navigationBar != nil else {
            return
        }
        
        var frame = navigationBar!.frame
        frame.size.height += 20 // include status bar
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = [purpleColour, orangeColour].map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.0)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        } else {
            gradientLayer.endPoint = CGPoint(x: 0.0, y: 1.0)
        }
        
        // render the gradient to a UIImage
        UIGraphicsBeginImageContext(frame.size)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        navigationBar!.setBackgroundImage(image, for: UIBarMetrics.default)
    }
    
    static func setNavigationBarBackground(_ navigationBar: UINavigationBar?) {
        setNavigationBarBackgroundGradient(navigationBar)
    }
}
