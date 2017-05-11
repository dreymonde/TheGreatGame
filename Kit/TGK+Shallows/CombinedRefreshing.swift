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

public enum Relevant<Value> {
    
    case relevant(Value)
    case notRelevant
    
    public var value: Value? {
        if case .relevant(let val) = self {
            return val
        }
        return nil
    }
    
    public var isRelevant: Bool {
        if case .relevant = self {
            return true
        }
        return false
    }
    
    public var isNotRelevant: Bool {
        return !isRelevant
    }
    
    public func map<OtherValue>(_ transform: (Value) -> OtherValue) -> Relevant<OtherValue> {
        switch self {
        case .relevant(let rel):
            return .relevant(transform(rel))
        case .notRelevant:
            return .notRelevant
        }
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
    
    func combinedRefreshing<CacheType : ReadableCacheProtocol>(with backCache: CacheType, isMoreRecent: @escaping (Value, Value) -> Bool) -> ReadOnlyCache<Key, Sourceful<Relevant<Value.Value>>> where CacheType.Key == Key, CacheType.Value == Value, Value : SourcefulProtocol {
        let name = "\(self.cacheName)<-~\(backCache.cacheName)"
        func log(_ message: String) {
            let nameInBrackets = "(\(name))"
            print(nameInBrackets, message)
        }
        return ReadOnlyCache<Key, Sourceful<Relevant<Value.Value>>>(cacheName: name, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (frontResult) in
                if case .success(let frontValue) = frontResult {
                    log("Front cache not failed, completing first time")
                    let sourceful = Sourceful(value: Relevant.relevant(frontValue.value), source: frontValue.source)
                    completion(.success(sourceful))
                } else {
                    log("Front cache failed, \(frontResult), retrieving from back")
                }
                backCache.retrieve(forKey: key, completion: { (backResult) in
                    switch backResult {
                    case .success(let backValue):
                        if let frontValue = frontResult.asOptional {
                            if isMoreRecent(backValue, frontValue) {
                                log("Backed value is more recent than existing, setting and completing second time")
                                let sourceful = Sourceful(value: Relevant.relevant(backValue.value), source: backValue.source)
                                self.set(backValue, forKey: key, completion: { _ in completion(.success(sourceful)) })
                            } else {
                                log("Backed value is not more recent, completing with .notRelevant")
                                let notRelevant = Sourceful(value: Relevant<Value.Value>.notRelevant, source: backValue.source)
                                completion(.success(notRelevant))
                            }
                        } else {
                            log("There is no existing value, setting and completing")
                            let sourceful = Sourceful(value: Relevant.relevant(backValue.value), source: backValue.source)
                            self.set(backValue, forKey: key, completion: { _ in completion(.success(sourceful)) })
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
