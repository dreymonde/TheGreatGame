//
//  Functions.swift
//  TheGreatGame
//
//  Created by Олег on 08.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public func rethrowing<In, Out>(_ block: @escaping (In) throws -> Out,
                       with recatch: @escaping (Error) -> Error = { $0 }) -> (In) throws -> Out {
    return { input in
        do {
            let output = try block(input)
            return output
        } catch {
            let rethrowed = recatch(error)
            throw rethrowed
        }
    }
}
