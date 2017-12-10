//
//  Shallows+Mapper.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

extension CacheProtocol where Value == [String : Any] {
    
    public func mapMappable<T : Mappable>(of type: T.Type = T.self) -> Cache<Key, T> {
        return mapValues(transformIn: T.init(from:),
                         transformOut: { try $0.map() })
    }
    
}

extension ReadOnlyCache where Value == [String : Any] {
    
    public func mapMappable<T : InMappable>(of type: T.Type = T.self) -> ReadOnlyCache<Key, T> {
        return mapValues(T.init(from:))
    }
    
}

extension WriteOnlyCache where Value == [String : Any] {
    
    public func mapMappable<T : OutMappable>(of type: T.Type = T.self) -> WriteOnlyCache<Key, T> {
        return mapValues({ try $0.map() })
    }
    
}

extension ReadOnlyCache {
    
    func mapKeys<OtherKey>(to type: OtherKey.Type, _ transform: @escaping (OtherKey) throws -> Key) -> ReadOnlyCache<OtherKey, Value> {
        return mapKeys(transform)
    }
    
}
