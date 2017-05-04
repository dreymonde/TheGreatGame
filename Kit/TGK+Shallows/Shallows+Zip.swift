//
//  Shallows+Zip.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public final class CompletionContainer<A, B> {
    
    private var ase: [A] = []
    private var bis: [B] = []
    private let queue = DispatchQueue(label: "container-completion")
    
    private let completion: (A, B) -> ()
    
    public init(completion: @escaping (A, B) -> ()) {
        self.completion = completion
    }
    
    public func complete(with a: A...) {
        queue.async {
            self.ase.append(contentsOf: a)
            self.check()
        }
    }
    
    public func complete(with b: B...) {
        queue.async {
            self.bis.append(contentsOf: b)
            self.check()
        }
    }
    
    private func check() {
        dispatchPrecondition(condition: .onQueue(queue))
        var cnt = 0
        while !ase.isEmpty && !bis.isEmpty {
            cnt += 1
            print(cnt)
            let a = ase.removeFirst()
            let b = bis.removeFirst()
            completion(a, b)
        }
    }
    
}

fileprivate extension Result {
    
    var error: Error? {
        if case .failure(let er) = self {
            return er
        }
        return nil
    }
    
}

public struct ResultZippedError : Error {
    
    public let left: Error?
    public let right: Error?
    
}

public func zip<Value1, Value2>(_ lhs: Shallows.Result<Value1>, _ rhs: Shallows.Result<Value2>) -> Result<(Value1, Value2)> {
    switch (lhs, rhs) {
    case (.success(let left), .success(let right)):
        return Result.success((left, right))
    default:
        return Result.failure(ResultZippedError(left: lhs.error, right: rhs.error))
    }
}

public func zip<Key, Value1, Value2>(_ lhs: ReadOnlyCache<Key, Value1>, _ rhs: ReadOnlyCache<Key, Value2>) -> ReadOnlyCache<Key, (Value1, Value2)> {
    return ReadOnlyCache(name: lhs.name + "+" + rhs.name, retrieve: { (key, completion) in
        let container = CompletionContainer<Result<Value1>, Result<Value2>> { left, right in
            completion(zip(left, right))
        }
        lhs.retrieve(forKey: key, completion: { container.complete(with: $0) })
        rhs.retrieve(forKey: key, completion: { container.complete(with: $0) })
    })
}
