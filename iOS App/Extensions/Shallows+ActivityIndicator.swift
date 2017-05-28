//
//  Extensions.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import Avenues

extension ReadOnlyCache {
    
    public func connectingNetworkActivityIndicator(manager: NetworkActivity.IndicatorManager) -> ReadOnlyCache<Key, Value> {
        return ReadOnlyCache.init(cacheName: self.cacheName, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                manager.decrement()
                completion(result)
            })
            manager.increment()
        })
    }
    
}

extension ReadOnlyCache where Value : HasSource {
    
    public func sourceful_connectingNetworkActivityIndicator(manager: NetworkActivity.IndicatorManager) -> ReadOnlyCache<Key, Value> {
        return ReadOnlyCache.init(cacheName: self.cacheName, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                if result.isLastRequest {
                    manager.decrement()
                }
                completion(result)
            })
            manager.increment()
        })
    }
    
}

extension CacheProtocol {
    
    public func connectingNetworkActivityIndicator(manager: NetworkActivity.IndicatorManager) -> Cache<Key, Value> {
        return Cache.init(cacheName: self.cacheName, retrieve: { (key, completion) in
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

extension ProcessorProtocol {
    
    public func connectingNetworkActivityIndicator(manager: NetworkActivity.IndicatorManager) -> Processor<Key, Value> {
        return Processor.init(start: { (key, completion) in
            self.start(key: key, completion: { (result) in
                manager.decrement()
                completion(result)
            })
            manager.increment()
        }, cancel: self.cancel(key:), getState: self.processingState(key:), cancelAll: self.cancelAll)
    }
    
}

