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
    
    public func renaming(to newName: String) -> Storage<Key, Value> {
        return Storage(storageName: newName, retrieve: self.retrieve, set: self.set)
    }
    
}

extension ReadOnlyStorage {
    
    public func renaming(to newName: String) -> ReadOnlyStorage<Key, Value> {
        return ReadOnlyStorage(storageName: newName, retrieve: self.retrieve)
    }
    
}

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

extension ReadOnlyStorage {
    
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
