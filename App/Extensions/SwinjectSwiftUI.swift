//
//  SwinjectSwiftUI.swift
//  Hackers
//
//  Created by Weiran Zhang on 04/04/2022.
//  Copyright © 2022 Glass Umbrella. All rights reserved.
//

import SwiftUI
import Swinject
import SwinjectStoryboard

@propertyWrapper
struct Inject<Component> {
    let wrappedValue: Component
    init() {
        self.wrappedValue = Resolver.shared.resolve(Component.self)
    }
}

class Resolver {
    static let shared = Resolver()
    private let container = buildContainer()

    func resolve<T>(_ type: T.Type) -> T {
        container.resolve(T.self)!
    }
}

func buildContainer() -> Container {
    let container = SwinjectStoryboard.defaultContainer

    container.register(SessionService.self) { _ in
        return SessionService()
    }.inObjectScope(.container)

    return container
}
