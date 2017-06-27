//
//  SerialCache.swift
//  TheGreatGame
//
//  Created by Олег on 10.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

extension CacheProtocol {
    
    public func renaming(to newName: String) -> Cache<Key, Value> {
        return Cache(cacheName: newName, retrieve: self.retrieve, set: self.set)
    }
    
}

extension ReadOnlyCache {
    
    public func renaming(to newName: String) -> ReadOnlyCache<Key, Value> {
        return ReadOnlyCache(cacheName: newName, retrieve: self.retrieve)
    }
    
}

extension CacheProtocol {
    
    public func serial() -> Cache<Key, Value> {
        let queue = DispatchQueue(label: "serial")
        return Cache(cacheName: self.cacheName, retrieve: { (key, completion) in
            queue.async {
                let sema = DispatchSemaphore(value: 0)
                self.retrieve(forKey: key, completion: { (result) in
                    completion(result)
                    sema.signal()
                })
                sema.wait()
            }
        }, set: { (value, key, completion) in
            queue.async {
                let sema = DispatchSemaphore(value: 0)
                self.set(value, forKey: key, completion: { (result) in
                    completion(result)
                    sema.signal()
                })
                sema.wait()
            }
        })
    }
    
}

extension ReadOnlyCache {
    
    public func serial() -> ReadOnlyCache<Key, Value> {
        let queue = DispatchQueue(label: "serial")
        return ReadOnlyCache(cacheName: self.cacheName, retrieve: { (key, completion) in
            queue.async {
                let sema = DispatchSemaphore(value: 0)
                self.retrieve(forKey: key, completion: { (result) in
                    completion(result)
                    sema.signal()
                })
                sema.wait()
            }
        })
    }
    
}
