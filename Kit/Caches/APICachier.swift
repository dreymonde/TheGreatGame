//
//  APICachier.swift
//  TheGreatGame
//
//  Created by Олег on 10.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public final class APICachier {
    
    fileprivate let diskCache = FileSystemCache.inDirectory(.cachesDirectory, appending: "storage-cache-msk1")
    fileprivate let diskJSONCache: Cache<String, [String : Any]>
    
    public init() {
        self.diskJSONCache = diskCache
            .mapJSONDictionary()
    }
    
    public func cachedLocally<Key, Value>(_ remoteCache: ReadOnlyCache<Key, Editioned<Value>>,
                              transformKey: @escaping (Key) -> String) -> ReadOnlyCache<Key, Sourceful<Relevant<Editioned<Value>>>> {
        let disk = diskJSONCache
            .mapKeys(transformKey)
            .mapMappable(of: Editioned<Value>.self)
            .withSource(.disk)
        return disk.combinedRefreshing(with: remoteCache.withSource(.server), isMoreRecent: { $0.value.isMoreRecent(than: $1.value) })
    }
    
}
