//
//  Sourceful.swift
//  TheGreatGame
//
//  Created by Олег on 10.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public enum Source {
    
    case memory
    case disk
    case server
    
    public var isAbsoluteTruth: Bool {
        return self == .server
    }
    
}

public protocol HasSource {
    
    var source: Source { get }
    
}

public protocol SourcefulProtocol : HasSource {
    
    associatedtype Value
    
    var value: Value { get }
    var source: Source { get }
    
}

public struct Sourceful<Value> : SourcefulProtocol {
    
    public var value: Value
    public var source: Source
    
    public init(value: Value, source: Source) {
        self.value = value
        self.source = source
    }
    
    public func map<OtherValue>(_ transform: (Value) -> OtherValue) -> Sourceful<OtherValue> {
        return Sourceful<OtherValue>(value: transform(self.value), source: source)
    }
    
    public func map<OtherValue>(_ transform: (Value) -> OtherValue?) -> Sourceful<OtherValue>? {
        if let tr = transform(self.value) {
            return Sourceful<OtherValue>(value: tr, source: source)
        }
        return nil
    }
    
}

extension Result where Value : HasSource {
    
    public var isLastRequest: Bool {
        switch self {
        case .failure:
            return true
        case .success(let value):
            return value.source.isAbsoluteTruth
        }
    }
    
}

extension ReadOnlyCache {
    
    public func withSource(_ source: Source) -> ReadOnlyCache<Key, Sourceful<Value>> {
        return self.mapValues({ Sourceful.init(value: $0, source: source) })
    }
    
}

extension CacheProtocol {
    
    public func withSource(_ source: Source) -> Cache<Key, Sourceful<Value>> {
        return self.mapValues(transformIn: { Sourceful.init(value: $0, source: source) },
                              transformOut: { $0.value })
    }
    
}
