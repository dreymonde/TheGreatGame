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

final class Resource<Value> {
    
    private var value: Value?
    
    private var local: ReadOnlyCache<Void, Value>
    private var provider: ReadOnlyCache<Void, Relevant<Value>>
    
    init(provider: ReadOnlyCache<Void, Relevant<Value>>,
         local: ReadOnlyCache<Void, Value> = .empty(),
         value: Value? = nil) {
        self.provider = provider
            .sourceful_connectingNetworkActivityIndicator()
            .mainThread()
        self.local = local
        self.value = value
    }
    
    convenience init<MappableValue : Mappable>(local: Cache<Void, Editioned<MappableValue>>,
                     remote: ReadOnlyCache<Void, Editioned<MappableValue>>,
                     transform: @escaping (MappableValue) -> Value,
                     value: Value? = nil) {
        let prov = local.withSource(.disk).combinedRefreshing(with: remote.withSource(.server),
                                                              isMoreRecent: { $0.value.isMoreRecent(than: $1.value) })
            .mapValues({ $0.map({ transform($0.content) }) })
        let loc = local.asReadOnlyCache()
            .mainThread()
            .mapValues({ transform($0.content) })
        self.init(provider: prov, local: loc, value: value)
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
    
    func load(completion: @escaping (Source) -> ()) {
        provider.retrieve { (result) in
            self.handle(result, with: completion)
        }
    }
    
    private func handle(_ result: Result<Relevant<Value>>, with completion: @escaping (Source) -> ()) {
        assert(Thread.isMainThread)
        switch result {
        case .success(let value):
            print("\(Value.self) relevance confirmed with:", value.source)
            if let relevant = value.valueIfRelevant {
                self.value = relevant
                completion(value.source)
            }
        case .failure(let error):
            print("Error loading \(self):", error)
        }
    }
    
    func reload(connectingToIndicator indicator: NetworkActivity.IndicatorManager, completion: @escaping (Source) -> ()) {
        indicator.increment()
        provider.retrieve { (result) in
            if result.isLastRequest {
                indicator.decrement()
                self.handle(result, with: completion)
            }
        }
    }
    
}
