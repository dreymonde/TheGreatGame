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
    
    fileprivate var local: Retrieve<Value>
    public var provider: Retrieve<Relevant<Value>>
    
    fileprivate let manager: NetworkActivityIndicatorManager
    
    public init(provider: Retrieve<Relevant<Value>>,
         local: Retrieve<Value> = .empty(),
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
    
    @available(*, deprecated, message: "Use fallible method instead")
    public func load(confirmation: @escaping () -> () = { }, completion: @escaping (Value, Source) -> ()) {
        self.load(confirmation: confirmation, onError: { _ in print("UNIMPLEMENTED") }, completion: completion)
    }
    
    public func load(confirmation: @escaping () -> () = { },
                     onError: @escaping (Error) -> (),
                     completion: @escaping (Value, Source) -> ()) {
        if let prefetched = getValue() {
            printWithContext("Completing with previously prefetched")
            completion(prefetched, .memory)
        }
        provider.retrieve { (result) in
            self.handle(result, confirmation: confirmation, errorHandling: onError, with: completion)
        }
    }
    
    private func handle(_ result: Result<Relevant<Value>>,
                        confirmation: @escaping () -> (),
                        errorHandling: @escaping (Error) -> (),
                        with completion: @escaping (Value, Source) -> ()) {
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
            errorHandling(error)
        }
    }
    
    @available(*, deprecated, message: "Use fallible method instead")
    public func reload(connectingToIndicator indicator: NetworkActivityIndicatorManager, completion: @escaping (Value, Source) -> ()) {
        self.reload(connectingToIndicator: indicator, onError: { _ in }, completion: completion)
    }
    
    public func reload(connectingToIndicator indicator: NetworkActivityIndicatorManager, onError: @escaping (Error) -> (), completion: @escaping (Value, Source) -> ()) {
        indicator.increment()
        provider.retrieve { (result) in
            if result.isLastRequest {
                indicator.decrement()
                self.handle(result, confirmation: { }, errorHandling: onError, with: completion)
            }
        }
    }
    
}

public final class Local<Value> {
    
    private let provider: Retrieve<Value>
    private var value: Value?
    
    public init(provider: Retrieve<Value>) {
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
                     remote: Retrieve<Editioned<Value>>,
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
    
    public static func testValue(_ value: Value, networkActivity manager: NetworkActivityIndicatorManager) -> Resource<Value> {
        let suc = DevCache.successing(with: value) as Cache<Void, Value>
        let relevant = suc.asReadOnlyCache().mapValues({ Relevant.init(valueIfRelevant: $0, source: Source.server, lastRelevant: $0) })
        return Resource(provider: relevant, local: suc.asReadOnlyCache(), networkActivity: manager, value: nil)
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
