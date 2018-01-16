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

extension ReadOnlyStorage {
    
    public func connectingNetworkActivityIndicator(indicator: NetworkActivityIndicator) -> ReadOnlyStorage<Key, Value> {
        return ReadOnlyStorage.init(storageName: self.storageName, retrieve: { (key, completion) in
            indicator.increment()
            self.retrieve(forKey: key, completion: { (result) in
                indicator.decrement()
                completion(result)
            })
        })
    }
    
}

extension WriteOnlyStorage {
    
    public func connectingNetworkActivityIndicator(manager: NetworkActivityIndicator) -> WriteOnlyStorage<Key, Value> {
        return WriteOnlyStorage.init(storageName: self.storageName, set: { (value, key, completion) in
            manager.increment()
            self.set(value, forKey: key, completion: { (result) in
                manager.decrement()
                completion(result)
            })
        })
    }
    
}

extension Shallows.StorageProtocol {
    
    public func connectingNetworkActivityIndicator(manager: NetworkActivityIndicator) -> Storage<Key, Value> {
        return Storage.init(storageName: self.storageName, retrieve: { (key, completion) in
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
    
    public func connectingNetworkActivityIndicator(manager: NetworkActivityIndicator) -> Processor<Key, Value> {
        return Processor.init(start: { (key, completion) in
            self.start(key: key, completion: { (result) in
                manager.decrement()
                completion(result)
            })
            manager.increment()
        }, cancel: self.cancel(key:), getState: self.processingState(key:), cancelAll: self.cancelAll)
    }
    
}

extension ReadOnlyStorage {
    
    public func mainThread() -> ReadOnlyStorage<Key, Value> {
        return ReadOnlyStorage.init(storageName: self.storageName, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                DispatchQueue.main.async {
                    completion(result)
                }
            })
        })
    }
    
}

extension WriteOnlyStorage {
    
    public func mainThread() -> WriteOnlyStorage<Key, Value> {
        return WriteOnlyStorage.init(storageName: self.storageName, set: { (value, key, completion) in
            self.set(value, forKey: key, completion: { (result) in
                DispatchQueue.main.async {
                    completion(result)
                }
            })
        })
    }
    
}
