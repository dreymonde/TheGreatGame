//
//  Functions.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public func rethrowing<In, Out>(_ block: @escaping (In) throws -> Out,
                       with recatch: @escaping (Error) -> Error = { $0 }) -> (In) throws -> Out {
    return { input in
        do {
            let output = try block(input)
            return output
        } catch {
            let rethrowed = recatch(error)
            throw rethrowed
        }
    }
}

public struct IntType<Meaning> : Hashable {
    
    public var hashValue: Int {
        return int.hashValue
    }
    
    public static func ==(lhs: IntType<Meaning>, rhs: IntType<Meaning>) -> Bool {
        return lhs.int == rhs.int
    }
    
    public let int: Int
    
    public init(_ int: Int) {
        self.int = int
    }
    
}

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
