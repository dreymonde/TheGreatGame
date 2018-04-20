//
//  Functions.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public final class LazyDictionary<Key : Hashable, Value> {
    
    let create: (Key) -> Value
    
    public var existing: [Key : Value]
    
    public init(_ existing: [Key : Value] = [:], create: @escaping (Key) -> Value) {
        self.existing = existing
        self.create = create
    }
    
    public func fill(for keys: Key...) {
        for key in keys {
            let new = create(key)
            self.existing[key] = new
        }
    }
    
    public subscript(key: Key) -> Value {
        if let existingValue = existing[key] {
            return existingValue
        } else {
            let new = create(key)
            self.existing[key] = new
            return new
        }
    }
    
}

public func objectID(_ object: AnyObject) -> ObjectIdentifier {
    return ObjectIdentifier(object)
}
