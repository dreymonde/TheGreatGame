import Dispatch
import Avenues
import Shallows

extension Shallows.Result {
    
    public var asProcessorResult: ProcessorResult<Value> {
        switch self {
        case .success(let value):
            return .success(value)
        case .failure(let error):
            return .failure(error)
        }
    }
    
}

extension Avenues.ProcessorProtocol where Key : Hashable {
    
    public func caching<CacheType : Shallows.StorageProtocol>(to cache: CacheType) -> Processor<Key, Value> where CacheType.Key == Key, CacheType.Value == Value {
        guard launchArgument(.isCachingDisabled) == false else {
            printWithContext("Not caching")
            return asProcessor()
        }
        let start: Processor<Key, Value>.Start = { key, completion in
            cache.retrieve(forKey: key, completion: { (cacheResult) in
                switch cacheResult {
                case .success(let cached):
                    completion(.success(cached))
                case .failure:
                    self.start(key: key, completion: { (processorResult) in
                        switch processorResult {
                        case .success(let processed):
                            cache.set(processed, forKey: key, completion: { _ in
                                completion(processorResult)
                            })
                        case .failure:
                            completion(processorResult)
                        }
                    })
                }
            })
        }
        return Processor<Key, Value>(start: start,
                                     cancel: self.cancel,
                                     cancelAll: self.cancelAll)
    }
    
}

