//
//  SwinjectSwiftUI.swift
//  Hackers
//
//  Created by Weiran Zhang on 04/04/2022.
//  Copyright © 2022 Glass Umbrella. All rights reserved.
//

import SwiftUI
import Swinject

@propertyWrapper
struct Inject<Component> {
    let wrappedValue: Component
    init() {
        self.wrappedValue = Resolver.shared.resolve(Component.self)
    }
}

class Resolver {
    static let shared = Resolver()
    private let container: Container

    init() {
        container = Container()
        setupDependencies()
    }

    private func setupDependencies() {
        // Register services with Swinject container
        container.register(SessionService.self) { _ in
            SessionService()
        }.inObjectScope(.container)
    }

    func resolve<T>(_ type: T.Type) -> T {
        container.resolve(T.self)!
    }
}
