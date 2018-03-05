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

extension ReadOnlyStorageProtocol {
    
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

extension WriteOnlyStorageProtocol {
    
    public func connectingNetworkActivityIndicator(indicator: NetworkActivityIndicator) -> WriteOnlyStorage<Key, Value> {
        return WriteOnlyStorage.init(storageName: self.storageName, set: { (value, key, completion) in
            indicator.increment()
            self.set(value, forKey: key, completion: { (result) in
                indicator.decrement()
                completion(result)
            })
        })
    }
    
}

extension Shallows.StorageProtocol {
    
    public func connectingNetworkActivityIndicator(indicator: NetworkActivityIndicator) -> Storage<Key, Value> {
        return Storage(read: asReadOnlyStorage().connectingNetworkActivityIndicator(indicator: indicator),
                       write: asWriteOnlyStorage().connectingNetworkActivityIndicator(indicator: indicator))
    }
    
}

extension ProcessorProtocol {
    
    public func connectingNetworkActivityIndicator(indicator: NetworkActivityIndicator) -> Processor<Key, Value> {
        return Processor.init(start: { (key, completion) in
            indicator.increment()
            self.start(key: key, completion: { (result) in
                indicator.decrement()
                completion(result)
            })
        }, cancel: self.cancel(key:), getState: self.processingState(key:), cancelAll: self.cancelAll)
    }
    
}

extension ReadOnlyStorageProtocol {
    
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

extension WriteOnlyStorageProtocol {
    
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
