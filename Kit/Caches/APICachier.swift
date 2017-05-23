//
//  APICachier.swift
//  TheGreatGame
//
//  Created by Олег on 10.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

extension APICachier {
    
    public static func dev() -> APICachier {
        return APICachier(diskJSONCache: .empty())
    }
    
    public static func inLocalCachesDirectory() -> APICachier {
        return APICachier(diskCache: .inDirectory(.cachesDirectory, appending: "storage-cache-msk2"))
    }
    
    public static func inSharedCachesDirectory() -> APICachier {
        return APICachier(diskCache: .inSharedContainer(appending: .caches(appending: "storage-cache-kha1")))
    }
    
    public static func inSharedDocumentsDirectory() -> APICachier {
        return APICachier(diskCache: FileSystemCache.inSharedContainer(appending: .documents(appending: "storage-cache-dnt-1")))
    }
    
}

public protocol CacheableKey {
    
    func asString() -> String
    
}

extension CacheableKey {
    
    static func represent(_ key: Self) -> String {
        return key.asString()
    }
    
}

public final class APICachier {
    
    fileprivate let diskJSONCache: Cache<String, [String : Any]>
    
    public init(diskCache: FileSystemCache) {
        print("File cache location:", diskCache.directoryURL)
        self.diskJSONCache = diskCache
            .mapJSONDictionary()
    }
    
    public init(diskJSONCache: Cache<String, [String : Any]>) {
        self.diskJSONCache = diskJSONCache
    }
    
    fileprivate var existing: [String : Any] = [:]
    
    private func cachedLocally<Key, Value>(_ remoteCache: ReadOnlyCache<Key, Editioned<Value>>,
                              transformKey: @escaping (Key) -> String,
                              token: String) -> ReadOnlyCache<Key, Relevant<Value>> {
        if let existingCache = existing[token] as? ReadOnlyCache<Key, Relevant<Value>> {
            print("Returning existing cache for token: \(token)")
            return existingCache
        }
        let disk = diskJSONCache
            .mapKeys(transformKey)
            .mapMappable(of: Editioned<Value>.self)
            .withSource(.disk)
        let memoryAndDisk = MemoryCache<String, Editioned<Value>>()
            .mapKeys(transformKey)
            .withSource(.memory)
            .combined(with: disk)
        let combined = memoryAndDisk.combinedRefreshing(with: remoteCache.withSource(.server), isMoreRecent: { $0.value.isMoreRecent(than: $1.value) })
            .mapValues({ $0.map({ $0.content }) })
        existing[token] = combined
        return combined
    }
    
    public func cachedLocally<Key : CacheableKey, Value>(_ remoteCache: ReadOnlyCache<Key, Editioned<Value>>,
                               token: String) -> ReadOnlyCache<Key, Relevant<Value>> {
        return self.cachedLocally(remoteCache, transformKey: Key.represent, token: token)
    }
    
    public func cachedLocally<Value>(_ remoteCache: ReadOnlyCache<Void, Editioned<Value>>,
                              key: String, token: String) -> ReadOnlyCache<Void, Relevant<Value>> {
        return self.cachedLocally(remoteCache, transformKey: { key }, token: token)
    }
    
}
