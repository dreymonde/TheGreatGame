//
//  Avenues.swift
//  Avenues
//
//  Created by Oleg Dreyman on 2/12/18.
//  Copyright © 2018 Avenues. All rights reserved.
//

import Foundation

public enum ResourceState<Value> {
    case existing(Value)
    case justArrived(Value)
    case processing
    
    var value: Value? {
        switch self {
        case .existing(let value):
            return value
        case .justArrived(let value):
            return value
        case .processing:
            return nil
        }
    }
}

public final class Avenue<Key : Hashable, Value> {
    
    public let cache: MemoryCache<Key, Value>
    public let scheduler: Scheduler<Key, Value>

    private var claims = Claims()
    
    private let queue = DispatchQueue(label: "avenue-queue")
    
    public convenience init(cache: MemoryCache<Key, Value>,
                            processor: Processor<Key, Value>) {
        let sch = AvenueScheduler(processor: processor)
        self.init(cache: cache, scheduler: sch)
    }
    
    public init(cache: MemoryCache<Key, Value>,
                scheduler: Scheduler<Key, Value>) {
        self.cache = cache
        self.scheduler = scheduler
    }
    
    public func manualRegister(claimer: AnyHashable,
                               for resourceKey: Key,
                               setup: @escaping (ResourceState<Value>) -> ()) {
        assert(Thread.isMainThread, "You can claim resources only on the main thread")
        let claim = Claim(key: resourceKey, setup: setup)
        claims[claimer] = claim
        self.run(requestFor: resourceKey) { (cachedValue) in
            if let cachedValue = cachedValue {
                setup(.existing(cachedValue))
            } else {
                setup(.processing)
            }
        }
    }
    
    public func register<Claimer : AnyObject & Hashable>(_ claimer: Claimer,
                                                         for resourceKey: Key,
                                                         setup: @escaping (Claimer, ResourceState<Value>) -> ()) {
        manualRegister(claimer: claimer, for: resourceKey) { [weak claimer] (value) in
            if let claimer = claimer {
                setup(claimer, value)
            }
        }
    }
    
    private func run(requestFor key: Key, existingValue block: (Value?) -> ()) {
        if let existing = cache.value(forKey: key) {
            block(existing)
            return
        }
        block(nil)
        onBackground {
            self.scheduler.process(key: key) { (result) in
                switch result {
                case .failure(let error):
                    print(key, error)
                case .success(let value):
                    self.resourceDidArrive(value, resourceKey: key)
                }
            }
        }
    }
    
    public func preload(key: Key) {
        run(requestFor: key, existingValue: { _ in })
    }
    
    public func cancel(key: Key) {
        onBackground {
            self.scheduler.cancelProcessing(key: key)
        }
    }
    
    public func cancelAll() {
        onBackground {
            self.scheduler.cancelAll()
        }
    }
    
    private func resourceDidArrive(_ resource: Value, resourceKey: Key) {
        onMain {
            let activeClaims = self.claims.claims(for: resourceKey)
            self.cache.set(resource, forKey: resourceKey)
            for (claim) in activeClaims {
                claim.setup(.justArrived(resource))
            }
        }
    }
    
}

extension Avenue {
    
    private func onMain(task: @escaping () -> ()) {
        DispatchQueue.main.async(execute: task)
    }
    
    private func onBackground(task: @escaping () -> ()) {
        queue.async(execute: task)
    }
    
}

extension Avenue {
    
    private struct Claims {
        
        private var claimersMap: [AnyHashable : Claim] = [:]
        private var keysMap: [Key : Set<AnyHashable>] = [:]
        
        subscript(claimer: AnyHashable) -> Claim? {
            get {
                return claimersMap[claimer]
            }
            set {
                if let oldClaim = claimersMap[claimer] {
                    let oldKey = oldClaim.key
                    keysMap[oldKey]?.remove(claimer)
                }
                claimersMap[claimer] = newValue
                if let newClaim = newValue {
                    keysMap[newClaim.key, default: []].insert(claimer)
                }
            }
        }
        
        func claims(for key: Key) -> [Claim] {
            return keysMap[key, default: []].flatMap({ claimer in claimersMap[claimer] })
        }
        
    }
    
    private struct Claim {
        
        let key: Key
        let setup: (ResourceState<Value>) -> ()
        
    }
    
}
