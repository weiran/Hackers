//
//  CollectionSafeAccess.swift
//  Shared
//
//  Provides bounds-checked subscripting for collections.
//

import Foundation

public extension Collection where Indices.Iterator.Element == Index {
    subscript(safe index: Index) -> Iterator.Element? {
        indices.contains(index) ? self[index] : nil
    }
}
