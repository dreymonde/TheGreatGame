//
//  AvenuesExtensions.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Avenues

extension ProcessorProtocol {
    
    public func connectingNetworkActivityIndicator(manager: NetworkActivity.IndicatorManager = .application) -> Processor<Key, Value> {
        return Processor.init(start: { (key, completion) in
            self.start(key: key, completion: { (result) in
                manager.decrement()
                completion(result)
            })
            manager.increment()
        }, cancel: self.cancel(key:), getState: self.processingState(key:), cancelAll: self.cancelAll)
    }
    
}
