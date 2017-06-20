//
//  TGK+Alba.swift
//  TheGreatGame
//
//  Created by Олег on 28.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba

public typealias AlbaAdapter<From, To> = (Subscribe<From>) -> Subscribe<To>

extension Subscribe {
    
    public func adapting<OtherEvent>(with adapter: @escaping AlbaAdapter<Event, OtherEvent>) -> Subscribe<OtherEvent> {
        return adapter(self)
    }
    
}

fileprivate extension Subscribe {
    
    func _mainThread() -> Subscribe<Event> {
        return rawModify(subscribe: { (id, handler) in
            self.manual.subscribe(objectWith: id, with: { (event) in
                DispatchQueue.main.async { handler(event) }
            })
        }, entry: ProxyPayload.Entry.custom("main-thread"))
    }

}

public struct MainThreadSubscribe<Event> {
    
    public let underlying: Subscribe<Event>
    
    public init(_ proxy: Subscribe<Event>) {
        self.underlying = proxy._mainThread()
    }
    
    public func subscribe<Object>(_ object: Object, with producer: @escaping (Object) -> (Event) -> ()) where Object : AnyObject {
        underlying.subscribe(object, with: producer)
    }
    
    public func flatSubscribe<Object>(_ object: Object, with handler: @escaping (Object, Event) -> ()) where Object : AnyObject {
        underlying.flatSubscribe(object, with: handler)
    }
    
}

extension Subscribe {
    
    public func mainThread() -> MainThreadSubscribe<Event> {
        return MainThreadSubscribe(self)
    }
    
    public func signed(with identifier: ObjectIdentifier?) -> SignedSubscribe<Event> {
        return map({ Signed.init($0, identifier) })
    }
    
    public func wait(seconds: TimeInterval) -> Subscribe<Event> {
        return rawModify(subscribe: { (identifier, handle) in
            self.manual.subscribe(objectWith: identifier, with: { (event) in
                DispatchQueue.global().asyncAfter(deadline: .now() + seconds, execute: { 
                    handle(event)
                })
            })
        }, entry: ProxyPayload.Entry.custom("wait-\(seconds)-seconds"))
    }
    
}

extension Subscribe {
    
    public func dispatched(to queue: DispatchQueue) -> Subscribe<Event> {
        return rawModify(subscribe: { (id, handler) in
            self.manual.subscribe(objectWith: id, with: { (event) in
                queue.async { handler(event) }
            })
        }, entry: ProxyPayload.Entry.custom("redispatched"))
    }
    
}

extension Subscribe {
    
    public func reuseValue<OtherEvent>(_ transforms: [(Event) -> OtherEvent]) -> Subscribe<OtherEvent> {
        return rawModify(subscribe: { (identifier, handle) in
            self.manual.subscribe(objectWith: identifier, with: { (event) in
                for transformed in transforms.map({ $0(event) }) {
                    handle(transformed)
                }
            })
        }, entry: ProxyPayload.Entry.transformation(label: "reused", ProxyPayload.Entry.Transformation.transformed(fromType: Event.self, toType: OtherEvent.self)))
    }
    
}

extension Subscribe where Event : Sequence {
    
    public func unfolded() -> Subscribe<Event.Iterator.Element> {
        return rawModify(subscribe: { (identifier, handler) in
            self.manual.subscribe(objectWith: identifier, with: { (sequence) in
                for element in sequence {
                    handler(element)
                }
            })
        }, entry: ProxyPayload.Entry.transformation(label: "unfolded", ProxyPayload.Entry.Transformation.transformed(fromType: Event.self, toType: Event.Iterator.Element.self)))
    }
    
}

