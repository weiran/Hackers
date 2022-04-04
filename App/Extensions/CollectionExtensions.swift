//
//  CollectionExtensions.swift
//  Hackers
//
//  Created by Weiran Zhang on 01/01/2022.
//  Copyright © 2022 Glass Umbrella. All rights reserved.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
