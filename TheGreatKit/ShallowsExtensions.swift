//
//  Extensions.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

extension ReadOnlyCache {
    
    public func connectingNetworkActivityIndicator(manager: NetworkActivity.IndicatorManager = .application) -> ReadOnlyCache<Key, Value> {
        return ReadOnlyCache.init(name: self.name, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                manager.decrement()
                completion(result)
            })
            manager.increment()
        })
    }
    
}

extension CacheProtocol {
    
    public func connectingNetworkActivityIndicator(manager: NetworkActivity.IndicatorManager = .application) -> Cache<Key, Value> {
        return Cache.init(name: self.name, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                manager.decrement()
                completion(result)
            })
            manager.increment()
        }, set: { (value, key, completion) in
            self.set(value, forKey: key, completion: { (result) in
                manager.decrement()
                completion(result)
            })
            manager.increment()
        })
    }
    
}
