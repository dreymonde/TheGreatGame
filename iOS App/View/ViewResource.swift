//
//  ViewResource.swift
//  TheGreatGame
//
//  Created by Олег on 17.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import TheGreatKit

func completion<Value>(_ completion: @escaping (Value) -> ()) -> (Value, Source) -> () {
    return { val, _ in
        completion(val)
    }
}

extension Relevant {
    
    func zipping<OtherValue>(_ other: OtherValue) -> Relevant<(Value, OtherValue)> {
        let vir: (Value, OtherValue)? = {
            if let selfvir = self.valueIfRelevant {
                return (selfvir, other)
            }
            return nil
        }()
        return Relevant<(Value, OtherValue)>(valueIfRelevant: vir, source: source, lastRelevant: (lastRelevant, other))
    }
    
}

final class ViewResource<Value> {
    
    private let provider: ReadOnlyCache<Void, Relevant<Value>>
    
    init(provider: ReadOnlyCache<Void, Relevant<Value>>) {
        self.provider = provider
            .sourceful_connectingNetworkActivityIndicator()
            .mainThread()
    }
    
    func load(completion: @escaping (Value, Source) -> ()) {
        provider.retrieve { (result) in
            self.handle(result, with: completion)
        }
    }
    
    func load<AnotherValue>(with anotherCache: ReadOnlyCache<Void, AnotherValue>, completion: @escaping (Value, AnotherValue, Source) -> ()) {
        zip(provider, anotherCache)
            .mainThread()
            .mapValues({ $0.0.zipping($0.1) })
            .retrieve { (result) in
            self.handle(result, with: { completion($0.0, $0.1, $1) })
        }
    }
    
    private func handle<HandlingValue>(_ result: Result<Relevant<HandlingValue>>, with completion: @escaping (HandlingValue, Source) -> ()) {
        assert(Thread.isMainThread)
        switch result {
        case .success(let value):
            print("\(Value.self) relevance confirmed with:", value.source)
            if let relevant = value.valueIfRelevant {
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
    
    func reload<AnotherValue>(with anotherCache: ReadOnlyCache<Void, AnotherValue>, connectingToIndicator indicator: NetworkActivity.IndicatorManager, completion: @escaping (Value, AnotherValue, Source) -> ()) {
        indicator.increment()
        zip(provider, anotherCache)
            .mainThread()
            .mapValues({ $0.0.zipping($0.1) })
            .retrieve { (result) in
            if result.isLastRequest {
                indicator.decrement()
                self.handle(result, with: { completion($0.0, $0.1, $1) })
            }
        }
    }
    
}
