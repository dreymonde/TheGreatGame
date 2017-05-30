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

public final class SingleElementMemoryCache<Value> : CacheProtocol {
    
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
        completion(.success())
    }
    
}

public enum TemporaryMemoryCacheError : Error {
    case expired
}

public final class TemporaryMemoryCache<Key : Hashable, Value> : CacheProtocol {
    
    private let queue = DispatchQueue(label: "temporary-memory-cache")
    private let internalCache: MemoryCache<Key, Value>
    private let interval: TimeInterval
    private var expired: Bool
    
    public init(interval: TimeInterval) {
        self.internalCache = MemoryCache()
        self.interval = interval
        self.expired = false
        self.startExpiration()
    }
    
    private func startExpiration() {
        self.queue.asyncAfter(deadline: .now() + interval) {
            self.expired = true
        }
    }
    
    public func retrieve(forKey key: Key, completion: @escaping (Result<Value>) -> ()) {
        queue.sync {
            if self.expired {
                completion(Result.failure(TemporaryMemoryCacheError.expired))
            } else {
                internalCache.retrieve(forKey: key, completion: completion)
            }
        }
    }
    
    public func set(_ value: Value, forKey key: Key, completion: @escaping (Result<Void>) -> ()) {
        queue.sync {
            self.expired = false
            internalCache.set(value, forKey: key, completion: completion)
            self.startExpiration()
        }
    }
    
}
