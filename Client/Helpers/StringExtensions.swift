//
//  StringExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 17/10/2017.
//  Copyright © 2017 Glass Umbrella. All rights reserved.
//

import Foundation

extension String {
    subscript(value: PartialRangeUpTo<Int>) -> Substring {
        get {
            return self[..<index(startIndex, offsetBy: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeThrough<Int>) -> Substring {
        get {
            return self[...index(startIndex, offsetBy: value.upperBound)]
        }
    }
    
    subscript(value: PartialRangeFrom<Int>) -> Substring {
        get {
            return self[index(startIndex, offsetBy: value.lowerBound)...]
        }
    }
}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

extension String {
    func parsedHTML() -> String {
        var text = self
        text = text.replacingOccurrences(of: "<p>", with: "\n\n")
        text = text.replacingOccurrences(of: "</p>", with: "")
        text = text.replacingOccurrences(of: "<i>", with: "")
        text = text.replacingOccurrences(of: "</i>", with: "")
        text = text.replacingOccurrences(of: "&#38;", with: "&")
        text = text.replacingOccurrences(of: "&#62;", with: ">")
        text = text.replacingOccurrences(of: "&#x27;", with: "'")
        text = text.replacingOccurrences(of: "&#x2F;", with: "/")
        text = text.replacingOccurrences(of: "&quot;", with: "\"")
        text = text.replacingOccurrences(of: "&#60;", with: "<")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&amp;", with: "")
        text = text.replacingOccurrences(of: "<pre><code>", with: "")
        text = text.replacingOccurrences(of: "</code></pre>", with: "")
        
        let scanner = Scanner(string: text)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "")
        var goodText: NSString?, runningString: NSString = "", trash: NSString?
        
        while !scanner.isAtEnd {
            if scanner.string[scanner.scanLocation...].range(of: "<a href") != nil {
                scanner.scanUpTo("<a href=", into: &goodText)
                runningString = runningString.appending(goodText! as String) as NSString
                scanner.scanString("<a href=\"", into: &trash)
                scanner.scanUpTo("\"", into: &goodText)
                runningString = runningString.appending(goodText! as String) as NSString
                scanner.scanUpTo("</a>", into: &trash)
                scanner.scanString("</a>", into: &trash)
            } else {
                let string = scanner.string[scanner.scanLocation...]
                runningString = runningString.appending(String(string)) as NSString
                scanner.scanLocation = text.count
            }
        }
        
        return runningString as String
    }
}
