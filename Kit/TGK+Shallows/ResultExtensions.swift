//
//  ResultExtensions.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

extension Shallows.Result {
    
    public func map<T>(_ transform: @escaping (Value) -> T) -> Result<T> {
        switch self {
        case .success(let value):
            return Result<T>.success(transform(value))
        case .failure(let error):
            return Result<T>.failure(error)
        }
    }
    
}
