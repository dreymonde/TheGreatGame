//
//  FireUpdate.swift
//  TheGreatGame
//
//  Created by Олег on 15.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public protocol FireUpdate {
    
    func fire(errorDelegate: ErrorStateDelegate)
    func fire(activityIndicator: NetworkActivityIndicator, errorDelegate: ErrorStateDelegate)
    
}

extension FireUpdate {
    
    public func fire(errorDelegate: ErrorStateDelegate) {
        self.fire(activityIndicator: .none, errorDelegate: errorDelegate)
    }
    
}

public struct EmptyFireUpdate : FireUpdate {
    
    public init() { }
    
    public func fire(errorDelegate: ErrorStateDelegate) {
        //
    }
    
    public func fire(activityIndicator: NetworkActivityIndicator, errorDelegate: ErrorStateDelegate) {
        //
    }
    
}

public struct APIFireUpdate<Value> : FireUpdate {
    
    let retrieve: Retrieve<Value>
    let write: (Value) -> Void
    
    public init(retrieve: Retrieve<Value>,
                write: @escaping (Value) -> Void,
                activityIndicator: NetworkActivityIndicator) {
        self.retrieve = retrieve
            .connectingNetworkActivityIndicator(indicator: activityIndicator)
            .mainThread()
        self.write = write
    }
    
    public func fire(activityIndicator: NetworkActivityIndicator, errorDelegate: ErrorStateDelegate) {
        activityIndicator.increment()
        retrieve.retrieve { (result) in
            activityIndicator.decrement()
            switch result {
            case .failure(let error):
                errorDelegate.errorDidOccur(error)
            case .success(let value):
                errorDelegate.errorDidNotOccur()
                self.write(value)
            }
        }
    }
    
}
