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
        var cacheInFlight = Set<Key>()
        let cacheInFlightLockQueue = DispatchQueue(label: "avenues+shallows.cache-in-flight-lock")
        let start: Processor<Key, Value>.Start = { key, completion in
            cache.retrieve(forKey: key, completion: { (cacheResult) in
                _ = cacheInFlightLockQueue.sync { cacheInFlight.remove(key) }
                switch cacheResult {
                case .success(let cached):
//                    if Avenues.Log.isEnabled {
//                        printWithContext("avenue-\(cache.storageName): quick access for key \(key)")
//                    }
                    completion(.success(cached))
                case .failure:
                    self.start(key: key, completion: { (processorResult) in
                        switch processorResult {
                        case .success(let fetched):
                            cache.set(fetched, forKey: key, completion: { _ in
                                completion(processorResult)
                            })
                        case .failure:
                            completion(processorResult)
                        }
                    })
                }
            })
            _ = cacheInFlightLockQueue.sync { cacheInFlight.insert(key) }
        }
        let getState: Processor<Key, Value>.GetState = { key in
            if cacheInFlightLockQueue.sync(execute: { cacheInFlight.contains(key) }) {
                return .running
            } else {
                return self.processingState(key: key)
            }
        }
        return Processor<Key, Value>(start: start,
                                     cancel: self.cancel,
                                     getState: getState,
                                     cancelAll: self.cancelAll)
    }
    
}

