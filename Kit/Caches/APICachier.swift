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
    
}

public final class APICachier {
    
    fileprivate let diskJSONCache: Cache<String, [String : Any]>
    
    public init(diskCache: FileSystemCache = .inDirectory(.cachesDirectory, appending: "storage-cache-msk2")) {
        print("File cache location:", diskCache.directoryURL)
        self.diskJSONCache = diskCache
            .mapJSONDictionary()
    }
    
    public init(diskJSONCache: Cache<String, [String : Any]>) {
        self.diskJSONCache = diskJSONCache
    }
    
    fileprivate var existing: [String : Any] = [:]
    
    public func cachedLocally<Key, Value>(_ remoteCache: ReadOnlyCache<Key, Editioned<Value>>,
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
    
}
