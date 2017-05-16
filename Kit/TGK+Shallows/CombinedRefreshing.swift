//
//  CombinedRefreshing.swift
//  TheGreatGame
//
//  Created by Олег on 10.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Shallows

public enum CombinedRefreshingError : Error {
    
    case backValueIsNotMoreRecent
    
}

public struct Relevant<Value> : HasSource {
    
    public var valueIfRelevant: Value?
    public var source: Source
    public var lastRelevant: Value
    
    public init(valueIfRelevant: Value?, source: Source, lastRelevant: Value) {
        self.valueIfRelevant = valueIfRelevant
        self.source = source
        self.lastRelevant = lastRelevant
    }
    
    public func map<OtherValue>(_ transform: (Value) -> OtherValue) -> Relevant<OtherValue> {
        return Relevant<OtherValue>(valueIfRelevant: valueIfRelevant.map(transform),
                                source: source,
                                lastRelevant: transform(lastRelevant))
    }
    
}

extension CacheProtocol {
    
    func combinedCompletingTwice<CacheType : ReadableCacheProtocol>(with backCache: CacheType) -> ReadOnlyCache<Key, Value> where CacheType.Key == Key, CacheType.Value == Value {
        return ReadOnlyCache<Key, Value>(cacheName: self.cacheName + "++" + backCache.cacheName, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (frontResult) in
                switch frontResult {
                case .success:
                    completion(frontResult)
                    fallthrough
                default:
                    backCache.retrieve(forKey: key, completion: { (backResult) in
                        switch backResult {
                        case .success(let value):
                            completion(.success(value))
                            self.set(value, forKey: key, completion: { _ in })
                        case .failure:
                            completion(backResult)
                        }
                    })
                }
            })
        })
    }
    
    func combinedRefreshing<CacheType : ReadableCacheProtocol>(with backCache: CacheType, isMoreRecent: @escaping (Value, Value) -> Bool) -> ReadOnlyCache<Key, Relevant<Value.Value>> where CacheType.Key == Key, CacheType.Value == Value, Value : SourcefulProtocol {
        let name = "\(self.cacheName)<-~\(backCache.cacheName)"
        func log(_ message: String) {
            let nameInBrackets = "(\(name))"
            print(nameInBrackets, message)
        }
        return ReadOnlyCache<Key, Relevant<Value.Value>>(cacheName: name, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (frontResult) in
                if case .success(let frontValue) = frontResult {
                    log("Front cache not failed, completing first time")
                    let relv = Relevant(valueIfRelevant: frontValue.value, source: frontValue.source, lastRelevant: frontValue.value)
                    completion(.success(relv))
                } else {
                    log("Front cache failed, \(frontResult), retrieving from back")
                }
                backCache.retrieve(forKey: key, completion: { (backResult) in
                    switch backResult {
                    case .success(let backValue):
                        if let frontValue = frontResult.asOptional {
                            if isMoreRecent(backValue, frontValue) {
                                log("Backed value is more recent than existing, setting and completing second time")
                                let relv = Relevant(valueIfRelevant: backValue.value, source: backValue.source, lastRelevant: backValue.value)
                                self.set(backValue, forKey: key, completion: { _ in completion(.success(relv)) })
                            } else {
                                log("Backed value is not more recent, completing with .notRelevant")
                                let notRelevant = Relevant(valueIfRelevant: nil, source: backValue.source, lastRelevant: frontValue.value)
                                completion(.success(notRelevant))
                            }
                        } else {
                            log("There is no existing value, setting and completing")
                            let relv = Relevant(valueIfRelevant: backValue.value, source: backValue.source, lastRelevant: backValue.value)
                            self.set(backValue, forKey: key, completion: { _ in completion(.success(relv)) })
                        }
                    case .failure(let error):
                        log("Retrieving from back cache failed")
                        completion(.failure(error))
                    }
                })
            })
        })
    }
        
}
