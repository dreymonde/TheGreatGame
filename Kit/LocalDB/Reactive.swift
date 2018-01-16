//
//  Reactive.swift
//  TheGreatGame
//
//  Created by Олег on 27.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba

public struct Reactive<Updating> {
    
    public let didUpdate: MainThreadSubscribe<Updating>
    public let update: FireUpdate
    
    public init(valueDidUpdate: MainThreadSubscribe<Updating>, update: FireUpdate) {
        self.didUpdate = valueDidUpdate
        self.update = update
    }
    
}
