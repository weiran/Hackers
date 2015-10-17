//
//  SCSafariViewController.swift
//  HackingSFViewController
//
//  Created by stringCode on 10/10/2015.
//  Copyright © 2015 stringCode. All rights reserved.
//

import UIKit
import SafariServices

class SCSafariViewController: SFSafariViewController {
    var edgeView: UIView? {
        get {
            if (_edgeView == nil && isViewLoaded()) {
                _edgeView = UIView()
                _edgeView?.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(_edgeView!)
                _edgeView?.backgroundColor = UIColor(white: 1.0, alpha: 0.005)
                let bindings = ["edgeView": _edgeView!]
                let options = NSLayoutFormatOptions(rawValue: 0)
                let hConstraints = NSLayoutConstraint.constraintsWithVisualFormat("|-0-[edgeView(5)]", options: options, metrics: nil, views: bindings)
                let vConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[edgeView]-0-|", options: options, metrics: nil, views: bindings)
                view?.addConstraints(hConstraints)
                view?.addConstraints(vConstraints)
            }
            return _edgeView
        }
    }
    
    private var _edgeView: UIView?
    
}