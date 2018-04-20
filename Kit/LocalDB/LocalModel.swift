//
//  TeamsModel.swift
//  TheGreatGame
//
//  Created by Олег on 15.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import Alba

public final class LocalModel<Value : Equatable> {
    
    public var io: Storage<Void, Value>!
    
    public var inMemory = ThreadSafe<Value?>(nil)
    
    public init(storage: Storage<Void, Value>) {
        let actualStorage: Storage<Void, Value> = launchArgument(.isCachingDisabled) ? SingleElementMemoryStorage().asStorage() : storage
        self.io = actualStorage.serial()
        self.populateInMemory()
    }
    
    public func populateInMemory() {
        if inMemory.read() == nil {
            io.retrieve(completion: { (result) in
                if let value = result.value {
                    self.set(value)
                }
            })
        }
    }
    
    public func getInMemory() -> Value? {
        return inMemory.read()
    }
    
    private let setQueue = DispatchQueue(label: "LocalModel.setQueue")
    public func set(_ newValue: Value) {
        setQueue.async {
            if newValue != self.inMemory.read() {
                self.inMemory.write(newValue)
                self.didUpdate.publish(newValue)
            }
        }
    }
    
    public func getPersisted() -> Value? {
        return try? getInMemory() ?? io.asReadOnlyStorage().makeSyncStorage().retrieve()
    }
    
    private let didUpdate = Publisher<Value>(label: "LocalModel<\(Value.self)>.didUpdate")
    public var inMemoryValueDidUpdate: Subscribe<Value> {
        return didUpdate.proxy
    }
    
}

extension LocalModel {
    
    public static func inStorage<T : Mappable>(_ diskStorage: Disk, filename: Filename) -> LocalModel<T> {
        let storage = diskStorage
            .mapJSONDictionary()
            .mapMappable(of: T.self)
            .memoryCached()
            .singleKey(filename)
        return LocalModel<T>(storage: storage)
    }
    
    public static func inStorage<T>(_ diskStorage: Disk, filename: Filename) -> LocalModel<[T]> where T : MappableBoxable {
        let storage = diskStorage
            .mapJSONDictionary()
            .mapMappable(of: [T].self)
            .memoryCached()
            .singleKey(filename)
        return LocalModel<[T]>(storage: storage)
    }
    
}

extension StorageProtocol where Key : Hashable {
    
    func memoryCached() -> Storage<Key, Value> {
        let memCache = MemoryStorage<Key, Value>()
        return memCache.combined(with: self)
    }
    
}
