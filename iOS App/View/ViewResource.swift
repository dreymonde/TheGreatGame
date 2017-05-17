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
    
    private func handle(_ result: Result<Relevant<Value>>, with completion: @escaping (Value, Source) -> ()) {
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
    
}
