//
//  Resource.swift
//  TheGreatGame
//
//  Created by Олег on 23.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import TheGreatKit

protocol Prefetchable {
    
    func prefetch()
    
}

final class Resource<Value> : Prefetchable {
    
    fileprivate var value: Value?
    
    fileprivate var local: ReadOnlyCache<Void, Value>
    fileprivate var provider: ReadOnlyCache<Void, Relevant<Value>>
    
    init(provider: ReadOnlyCache<Void, Relevant<Value>>,
         local: ReadOnlyCache<Void, Value> = .empty(),
         value: Value? = nil) {
        self.provider = provider
            .sourceful_connectingNetworkActivityIndicator()
            .mainThread()
        self.local = local
        self.value = value
    }
    
    func getValue() -> Value? {
        return value
    }
    
    func prefetch() {
        local.retrieve { (result) in
            assert(Thread.isMainThread)
            printWithContext("Prefetched \(Value.self)")
            if let retrieved = result.asOptional {
                self.value = retrieved
            }
        }
    }
    
    func load(completion: @escaping (Value, Source) -> ()) {
        if let prefetched = getValue() {
            printWithContext("Completing with previously prefetched")
            completion(prefetched, .memory)
        }
        provider.retrieve { (result) in
            self.handle(result, with: completion)
        }
    }
    
    private func handle(_ result: Result<Relevant<Value>>, with completion: @escaping (Value, Source) -> ()) {
        assert(Thread.isMainThread)
        switch result {
        case .success(let value):
            print("\(Value.self) relevance confirmed with:", value.source)
            if let relevant = value.valueIfRelevant {
                self.value = relevant
                completion(relevant, value.source)
            }
        case .failure(let error):
            print("Error loading \(self):", error)
        }
    }
    
    func reload(connectingToIndicator indicator: NetworkActivity.IndicatorManager, completion: @escaping (Value, Source) -> ()) {
        indicator.increment()
        provider.retrieve { (result) in
            if result.isLastRequest {
                indicator.decrement()
                self.handle(result, with: completion)
            }
        }
    }
    
}

final class Local<Value> {
    
    private let provider: ReadOnlyCache<Void, Value>
    private var value: Value?
    
    init(provider: ReadOnlyCache<Void, Value>) {
        self.provider = provider
            .mainThread()
    }
    
    func retrieve(_ completion: @escaping (Value) -> ()) {
        provider.retrieve { (result) in
            assert(Thread.isMainThread)
            if let value = result.asOptional {
                completion(value)
            }
        }
    }
    
}

extension Resource where Value : Mappable {
    
    convenience init(local: Cache<Void, Editioned<Value>>,
                     remote: ReadOnlyCache<Void, Editioned<Value>>,
                     value: Value? = nil) {
        let prov = local.withSource(.disk).combinedRefreshing(with: remote.withSource(.server),
                                                              isMoreRecent: { $0.value.isMoreRecent(than: $1.value) })
            .mapValues({ $0.map({ $0.content }) })
        let loc = local.asReadOnlyCache()
            .mainThread()
            .mapValues({ $0.content })
        self.init(provider: prov, local: loc, value: value)
    }

    
}

extension Resource {
    
    func map<OtherValue>(_ transform: @escaping (Value) -> OtherValue) -> Resource<OtherValue> {
        return Resource<OtherValue>(provider: provider.mapValues({ $0.map(transform) }),
                                    local: local.mapValues(transform),
                                    value: value.map(transform))
    }
    
}
