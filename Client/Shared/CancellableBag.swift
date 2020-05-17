//
//  CancellableBag.swift
//  CombineExamples
//
//  Created by Pawel Krawiec on 18/06/2019.
//  Copyright © 2019 tailec. All rights reserved.
//
import Combine

class CancellableBag {
    var bag = [Cancellable]()
    func insert(_ cancellable: Cancellable) {
        bag.append(cancellable)
    }
    deinit {
        let copy = bag
        bag = []
        copy.forEach { $0.cancel() }
    }
}

extension Cancellable {
    func cancelled(by bag: CancellableBag) {
        bag.insert(self)
    }
}
