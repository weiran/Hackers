//
//  StringExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 17/10/2017.
//  Copyright © 2017 Weiran Zhang. All rights reserved.
//

import Foundation

extension String {
    subscript(value: PartialRangeUpTo<Int>) -> Substring {
        return self[..<index(startIndex, offsetBy: value.upperBound)]
    }

    subscript(value: PartialRangeThrough<Int>) -> Substring {
        return self[...index(startIndex, offsetBy: value.upperBound)]
    }

    subscript(value: PartialRangeFrom<Int>) -> Substring {
        return self[index(startIndex, offsetBy: value.lowerBound)...]
    }
}

