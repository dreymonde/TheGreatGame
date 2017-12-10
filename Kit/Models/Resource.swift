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

public protocol ErrorStateDelegate : class {
    
    func errorDidOccur(_ error: Error)
    func errorDidNotOccur()
    
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
    
    public func load(completion: @escaping (Value, Source) -> ()) {
        self.load(errorDelegate: UnimplementedErrorStateDelegate.shared, completion: completion)
    }
    
    public func load(errorDelegate: ErrorStateDelegate,
                     completion: @escaping (Value, Source) -> ()) {
        if let prefetched = getValue() {
            printWithContext("Completing with previously prefetched")
            completion(prefetched, .memory)
        }
        provider.retrieve { (result) in
            self.handle(result, errorDelegate: errorDelegate, with: completion)
        }
    }
    
    private func handle(_ result: Result<Relevant<Value>>,
                        errorDelegate: ErrorStateDelegate,
                        with completion: @escaping (Value, Source) -> ()) {
        assert(Thread.isMainThread)
        switch result {
        case .success(let value):
            self.isAbsoluteTruth = value.source.isAbsoluteTruth
            if value.source.isAbsoluteTruth {
                errorDelegate.errorDidNotOccur()
            }
            print("\(Value.self) relevance confirmed with:", value.source)
            if let relevant = value.valueIfRelevant {
                self.value = relevant
                completion(relevant, value.source)
            }
        case .failure(let error):
            print("Error loading \(self):", error)
            errorDelegate.errorDidOccur(error)
        }
    }
    
    public func reload(connectingToIndicator indicator: NetworkActivityIndicatorManager,
                       completion: @escaping (Value, Source) -> ()) {
        self.reload(connectingToIndicator: indicator,
                    errorDelegate: UnimplementedErrorStateDelegate.shared,
                    completion: completion)
    }
    
    public func reload(connectingToIndicator indicator: NetworkActivityIndicatorManager,
                       errorDelegate: ErrorStateDelegate,
                       completion: @escaping (Value, Source) -> ()) {
        indicator.increment()
        provider.retrieve { (result) in
            if result.isLastRequest {
                indicator.decrement()
                self.handle(result, errorDelegate: errorDelegate, with: completion)
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

fileprivate class UnimplementedErrorStateDelegate : ErrorStateDelegate {
    
    func errorDidOccur(_ error: Error) {
        printWithContext("Unimplemented")
    }
    
    func errorDidNotOccur() {
        printWithContext("Unimplemented")
    }
    
    static let shared = UnimplementedErrorStateDelegate()
    
}
