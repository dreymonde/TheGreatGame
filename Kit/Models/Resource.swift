//
//  Resource.swift
//  TheGreatGame
//
//  Created by Олег on 23.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public protocol Prefetchable {
    
    func prefetch()
    
}

public final class Resource<Value> : Prefetchable {
    
    fileprivate var value: Value?
    
    fileprivate var local: ReadOnlyCache<Void, Value>
    public var provider: ReadOnlyCache<Void, Relevant<Value>>
    
    fileprivate let manager: NetworkActivityIndicatorManager
    
    public init(provider: ReadOnlyCache<Void, Relevant<Value>>,
         local: ReadOnlyCache<Void, Value> = .empty(),
         networkActivity manager: NetworkActivityIndicatorManager,
         value: Value? = nil) {
        self.manager = manager
        self.provider = provider
            .sourceful_connectingNetworkActivityIndicator(manager: manager)
            .mainThread()
        self.local = local
        self.value = value
    }
    
    public func getValue() -> Value? {
        return value
    }
    
    public var isAbsoluteTruth: Bool = false
    
    public func prefetch() {
        local.retrieve { (result) in
            assert(Thread.isMainThread)
            printWithContext("Prefetched \(Value.self)")
            if let retrieved = result.value {
                self.value = retrieved
            }
        }
    }
    
    public func addActivityIndicator(_ activityIndicator: NetworkActivityIndicatorManager) {
        self.provider = self.provider.sourceful_connectingNetworkActivityIndicator(manager: activityIndicator)
    }
    
    public func load(confirmation: @escaping () -> () = { }, completion: @escaping (Value, Source) -> ()) {
        if let prefetched = getValue() {
            printWithContext("Completing with previously prefetched")
            completion(prefetched, .memory)
        }
        provider.retrieve { (result) in
            self.handle(result, confirmation: confirmation, with: completion)
        }
    }
    
    private func handle(_ result: Result<Relevant<Value>>, confirmation: @escaping () -> (), with completion: @escaping (Value, Source) -> ()) {
        assert(Thread.isMainThread)
        switch result {
        case .success(let value):
            self.isAbsoluteTruth = value.source.isAbsoluteTruth
            print("\(Value.self) relevance confirmed with:", value.source)
            if let relevant = value.valueIfRelevant {
                self.value = relevant
                completion(relevant, value.source)
            } else if value.source.isAbsoluteTruth {
                confirmation()
            }
        case .failure(let error):
            print("Error loading \(self):", error)
        }
    }
    
    public func reload(connectingToIndicator indicator: NetworkActivityIndicatorManager, completion: @escaping (Value, Source) -> ()) {
        indicator.increment()
        provider.retrieve { (result) in
            if result.isLastRequest {
                indicator.decrement()
                self.handle(result, confirmation: { }, with: completion)
            }
        }
    }
    
}

public final class Local<Value> {
    
    private let provider: ReadOnlyCache<Void, Value>
    private var value: Value?
    
    public init(provider: ReadOnlyCache<Void, Value>) {
        self.provider = provider
            .mainThread()
    }
    
    public func retrieve(_ completion: @escaping (Value) -> ()) {
        provider.retrieve { (result) in
            assert(Thread.isMainThread)
            if let value = result.value {
                completion(value)
            }
        }
    }
    
}

extension Resource where Value : Mappable {
    
    public convenience init(local: Cache<Void, Editioned<Value>>,
                     remote: ReadOnlyCache<Void, Editioned<Value>>,
                     networkActivity manager: NetworkActivityIndicatorManager,
                     value: Value? = nil) {
        let prov = local.withSource(.disk).combinedRefreshing(with: remote.withSource(.server),
                                                              isMoreRecent: { $0.value.isMoreRecent(than: $1.value) })
            .mapValues({ $0.map({ $0.content }) })
        let loc = local.asReadOnlyCache()
            .mainThread()
            .mapValues({ $0.content })
        self.init(provider: prov, local: loc, networkActivity: manager, value: value)
    }

    
}

extension Resource {
    
    public func map<OtherValue>(_ transform: @escaping (Value) -> OtherValue) -> Resource<OtherValue> {
        return Resource<OtherValue>(provider: provider.mapValues({ $0.map(transform) }),
                                    local: local.mapValues(transform),
                                    networkActivity: self.manager,
                                    value: value.map(transform))
    }
    
}
