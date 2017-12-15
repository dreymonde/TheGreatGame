//
//  SingleElementMemoryCache.swift
//  TheGreatGame
//
//  Created by Олег on 23.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public enum SingleElementMemoryCacheError : Error {
    case noValue
}

public final class SingleElementMemoryStorage<Value> : StorageProtocol {
    
    public typealias Key = Void
    
    private let queue = DispatchQueue(label: "single-element-cache-sync", qos: .userInteractive)
    
    private var _value: Value?
    
    public init(_ value: Value?) {
        self._value = value
    }
    
    public init() {
        self._value = nil
    }
    
    public var value: Value? {
        get {
            return queue.sync(execute: { _value })
        }
        set {
            queue.sync(execute: { _value = newValue })
        }
    }
    
    public func retrieve(forKey key: Void, completion: @escaping (Result<Value>) -> ()) {
        if let value = value {
            completion(.success(value))
        } else {
            completion(.failure(SingleElementMemoryCacheError.noValue))
        }
    }
    
    public func set(_ value: Value, forKey key: Void, completion: @escaping (Result<Void>) -> ()) {
        self.value = value
        completion(.success)
    }
    
}

public enum TemporaryMemoryCacheError : Error {
    case expired
}
