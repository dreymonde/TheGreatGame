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
    
    public let proxy: MainThreadSubscribe<Updating>
    public let update: FireUpdate
    
    public init(proxy: MainThreadSubscribe<Updating>, update: FireUpdate) {
        self.proxy = proxy
        self.update = update
    }
    
}
