//
//  SerialCache.swift
//  TheGreatGame
//
//  Created by Олег on 10.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

extension StorageProtocol {
    
    public func serial() -> Storage<Key, Value> {
        let queue = DispatchQueue(label: "serial")
        return Storage(storageName: self.storageName, retrieve: { (key, completion) in
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

extension ReadOnlyStorageProtocol {
    
    public func serial() -> ReadOnlyStorage<Key, Value> {
        let queue = DispatchQueue(label: "serial")
        return ReadOnlyStorage(storageName: self.storageName, retrieve: { (key, completion) in
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
