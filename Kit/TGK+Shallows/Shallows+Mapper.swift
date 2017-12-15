//
//  Shallows+Mapper.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

extension StorageProtocol where Value == [String : Any] {
    
    public func mapMappable<T : Mappable>(of type: T.Type = T.self) -> Storage<Key, T> {
        return mapValues(transformIn: T.init(from:),
                         transformOut: { try $0.map() })
    }
    
}

extension ReadOnlyStorage where Value == [String : Any] {
    
    public func mapMappable<T : InMappable>(of type: T.Type = T.self) -> ReadOnlyStorage<Key, T> {
        return mapValues(T.init(from:))
    }
    
}

extension WriteOnlyStorage where Value == [String : Any] {
    
    public func mapMappable<T : OutMappable>(of type: T.Type = T.self) -> WriteOnlyStorage<Key, T> {
        return mapValues({ try $0.map() })
    }
    
}

extension ReadOnlyStorage {
    
    func mapKeys<OtherKey>(to type: OtherKey.Type, _ transform: @escaping (OtherKey) throws -> Key) -> ReadOnlyStorage<OtherKey, Value> {
        return mapKeys(transform)
    }
    
}
