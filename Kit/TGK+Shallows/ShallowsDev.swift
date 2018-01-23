//
//  ShallowsTesting.swift
//  TheGreatGame
//
//  Created by Олег on 25.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public enum DevCacheError : Error {
    case sorryPal
}

#if os(iOS)
    extension Storage {
        
        public func benchmarked() -> Storage<Key, Value> {
            let name = self.storageName
            return Storage<Key, Value>(storageName: self.storageName, retrieve: { (key, completion) in
                let start = CACurrentMediaTime()
                self.retrieve(forKey: key, completion: { (result) in
                    let end = CACurrentMediaTime()
                    let diff = end - start
                    print("[RET] SHALLOWS BENCHMARK \(name):", diff)
                    completion(result)
                })
            }, set: { (value, key, completion) in
                let start = CACurrentMediaTime()
                self.set(value, forKey: key, completion: { (result) in
                    let end = CACurrentMediaTime()
                    let diff = end - start
                    print("[SET] SHALLOWS BENCHMARK \(name):", diff)
                })
            })
        }
        
    }
#endif

public enum DevStorage<Key, Value> {
    
    public static func successing(with value: Value) -> Storage<Key, Value> {
        return Storage<Key, Value>(storageName: "dev-success", retrieve: { (_, completion) in
            completion(.success(value))
        }, set: { (_, _, completion) in
            completion(.success)
        })
    }
    
    public static func failing(with error: Error = DevCacheError.sorryPal) -> Storage<Key, Value> {
        return Storage<Key, Value>(storageName: "dev-failure", retrieve: { (_, completion) in
            completion(.failure(error))
        }, set: { (_, _, completion) in
            completion(.failure(error))
        })
    }
    
}
