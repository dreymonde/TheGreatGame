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

public final class LocalModel<Value> {
    
    private var storage: Storage<Void, Value>!
    public var io: Storage<Void, Value> {
        return storage
    }
    
    public var inMemory = ThreadSafe<Value?>(nil)
    
    public init(storage: Storage<Void, Value>) {
        let stor = storage
            .writing(to: { new in self.inMemory.write(new) })
            .writing(to: { new in self.didUpdate.publish(new) })
        self.storage = stor
    }
    
    public var ioRead: Retrieve<Value> {
        return io.asReadOnlyStorage()
    }
    
    public var ioWrite: WriteOnlyStorage<Void, Value> {
        return io.asWriteOnlyStorage()
    }
    
    public func prefetch() {
        ioRead.retrieve(completion: { _ in printWithContext("Prefetched \(Value.self)") })
    }
    
    public func getInMemory() -> Value? {
        return inMemory.read()
    }
    
    public func getPersisted() -> Value? {
        return try? getInMemory() ?? ioRead.makeSyncStorage().retrieve()
    }
    
    public func update(with newValue: Value) {
        ioWrite.set(newValue)
    }
    
    public let didUpdate = Publisher<Value>(label: "LocalModel<\(Value.self)>.didUpdate")
    
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

extension Storage where Key == Void {
    
    public func writing(to memoryWrite: @escaping (Value) -> ()) -> Storage<Key, Value> {
        return Storage<Key, Value>(storageName: self.storageName, retrieve: { (_, completion) in
            self.retrieve(completion: { (result) in
                if let value = result.value {
                    memoryWrite(value)
                }
                completion(result)
            })
        }, set: { (value, _, completion) in
            memoryWrite(value)
            self.set(value, forKey: (), completion: completion)
        })
    }
    
}
