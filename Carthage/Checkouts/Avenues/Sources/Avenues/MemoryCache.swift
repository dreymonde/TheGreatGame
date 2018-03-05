//
//  Cache.swift
//  Avenues
//
//  Created by Олег on 12.02.2018.
//  Copyright © 2018 Avenues. All rights reserved.
//

import Foundation

public protocol MemoryCacheProtocol {
    
    associatedtype Key
    associatedtype Value
    
    func value(forKey key: Key) -> Value?
    func set(_ value: Value, forKey key: Key)
    
}

extension MemoryCacheProtocol {
    
    public func asCache() -> MemoryCache<Key, Value> {
        return MemoryCache(self)
    }
    
}

public struct MemoryCache<Key, Value> : MemoryCacheProtocol {
    
    private let get: (Key) -> Value?
    private let set: (Value, Key) -> ()
    
    public init(get: @escaping (Key) -> Value?,
                set: @escaping (Value, Key) -> ()) {
        self.get = get
        self.set = set
    }
    
    public init<Cache : MemoryCacheProtocol>(_ cache: Cache) where Cache.Key == Key, Cache.Value == Value {
        self.init(get: cache.value, set: cache.set)
    }
    
    private func assertMainQueue() {
        assert(Thread.isMainThread)
    }
    
    public func value(forKey key: Key) -> Value? {
        assertMainQueue()
        return get(key)
    }
    
    public func set(_ value: Value, forKey key: Key) {
        assertMainQueue()
        set(value, key)
    }
    
}

extension MemoryCache where Key : Hashable {
    
    public static func dictionaryBased() -> MemoryCache<Key, Value> {
        return DictionaryBasedCache().asCache()
    }
    
}

extension MemoryCacheProtocol {
    
    public func mapKeys<OtherKey>(to keyType: OtherKey.Type = OtherKey.self,
                                  _ transform: @escaping (OtherKey) -> Key) -> MemoryCache<OtherKey, Value> {
        let get: (OtherKey) -> Value? = { otherKey in return self.value(forKey: transform(otherKey)) }
        let set: (Value, OtherKey) -> () = { value, otherKey in self.set(value, forKey: transform(otherKey)) }
        return MemoryCache(get: get, set: set)
    }
    
    public func mapValues<OtherValue>(to valueType: OtherValue.Type = OtherValue.self,
                                      transformIn: @escaping (Value) -> OtherValue?,
                                      transformOut: @escaping (OtherValue) -> Value) -> MemoryCache<Key, OtherValue> {
        return MemoryCache<Key, OtherValue>(get: { (key) -> OtherValue? in
            return self.value(forKey: key).flatMap(transformIn)
        }, set: { (otherValue, key) in
            self.set(transformOut(otherValue), forKey: key)
        })
    }
        
}

public final class DictionaryBasedCache<Key : Hashable, Value> : MemoryCacheProtocol {
    
    public var dictionary: [Key : Value]
    
    public init(dictionary: [Key : Value] = [:]) {
        self.dictionary = dictionary
    }
    
    public func value(forKey key: Key) -> Value? {
        return dictionary[key]
    }
    
    public func set(_ value: Value, forKey key: Key) {
        dictionary[key] = value
    }
    
}


#if os(iOS) || os(OSX) || os(watchOS) || os(tvOS)
    
    public final class NSCacheCache<Key : AnyObject, Value : AnyObject> : MemoryCacheProtocol where Key : Hashable {
        
        public var cache: NSCache<Key, Value>
        
        public init(cache: NSCache<Key, Value> = NSCache()) {
            self.cache = cache
        }
        
        public func value(forKey key: Key) -> Value? {
            return cache.object(forKey: key)
        }
        
        public func set(_ value: Value, forKey key: Key) {
            cache.setObject(value, forKey: key)
        }
        
        public func remove(valueAt key: Key) {
            cache.removeObject(forKey: key)
        }
        
        public func clear() {
            self.cache = NSCache()
        }
        
    }
    
    public func NSCacheCacheBoxedKey<Key : Hashable, Value : AnyObject>() -> MemoryCache<Key, Value> {
        return NSCacheCache<NSCacheKeyBox<Key>, Value>().mapKeys(NSCacheKeyBox.init)
    }
    
    internal final class NSCacheKeyBox<Value : Hashable> : NSObject {
        
        internal let boxed: Value
        
        internal init(_ value: Value) {
            self.boxed = value
        }
        
        internal override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? NSCacheKeyBox<Value> else {
                return false
            }
            return self.boxed == other.boxed
        }
        
        internal override var hash: Int {
            return boxed.hashValue
        }
        
    }
    
#endif
