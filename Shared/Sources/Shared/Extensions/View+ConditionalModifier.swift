//
//  View+ConditionalModifier.swift
//  Shared
//
//  Applies a transformation to a view only when a condition is met.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func `if`(_ condition: Bool, transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
