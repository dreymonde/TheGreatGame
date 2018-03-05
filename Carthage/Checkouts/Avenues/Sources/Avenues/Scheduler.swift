//
//  Scheduler.swift
//  NewAvenue
//
//  Created by Олег on 04.03.2018.
//  Copyright © 2018 Heeveear Proto. All rights reserved.
//

import Foundation

open class Scheduler<Key, Value> {
    
    open let processor: Processor<Key, Value>
    
    public init(processor: Processor<Key, Value>) {
        self.processor = processor
    }
    
    open func process(key: Key, completion: @escaping (ProcessorResult<Value>) -> ()) {
        return
    }
    
    open func cancelProcessing(key: Key) {
        return
    }
    
    open func cancelAll() {
        return
    }
    
}

public final class AvenueScheduler<Key : Hashable, Value> : Scheduler<Key, Value> {
    
    public override init(processor: Processor<Key, Value>) {
        self.runningTasks = Synchronized(CountedSet())
        super.init(processor: processor)
    }
    
    private var runningTasks: Synchronized<CountedSet<Key>>
    
    public override func process(key: Key, completion: @escaping (ProcessorResult<Value>) -> ()) {
        let shouldStart: Bool = runningTasks.transaction { (running) in
            if running.contains(key) {
                running.add(key)
                return false
            }
            running.add(key)
            return true
        }
        if shouldStart {
            processor.start(key: key, completion: { (result) in
                self.request(for: key, didFinishWith: result, completion: completion)
            })
        }
    }
    
    private func request(for key: Key,
                         didFinishWith result: ProcessorResult<Value>,
                         completion: @escaping (ProcessorResult<Value>) -> ()) {
        let shouldComplete: Bool = self.runningTasks.transaction(with: { running in
            if running.contains(key) {
                running.clear(key)
                return true
            }
            return false
        })
        if shouldComplete {
            completion(result)
        }
        
    }
    
    public override func cancelProcessing(key: Key) {
        let shouldCancel: Bool = runningTasks.transaction(with: { (running) in
            running.remove(key)
            if !running.contains(key) {
                return true
            } else {
                return false
            }
        })
        if shouldCancel {
            processor.cancel(key: key)
        }
    }
    
    public override func cancelAll() {
        runningTasks.transaction(with: { (running) in
            running = CountedSet()
        })
        processor.cancelAll()
    }
    
}

internal struct CountedSet<Element : Hashable> {
    
    private var storage: [Element : UInt] = [:]
    
    init() { }
    
    init<C : Collection>(_ collection: C) where C.Element == Element {
        for element in collection {
            self.add(element)
        }
    }
    
    func contains(_ element: Element) -> Bool {
        return count(for: element) > 0
    }
    
    func count(for key: Element) -> UInt {
        return storage[key, default: 0]
    }
    
    mutating func add(_ element: Element) {
        storage[element, default: 0] += 1
    }
    
    mutating func remove(_ element: Element) {
        if let currentCount = storage[element] {
            if currentCount > 1 {
                storage[element] = currentCount - 1
            } else {
                storage.removeValue(forKey: element)
            }
        }
    }
    
    mutating func clear(_ element: Element) {
        storage.removeValue(forKey: element)
    }
    
}
