//
//  TGK+Alba.swift
//  TheGreatGame
//
//  Created by Олег on 28.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba

extension Subscribe {
    
    public func mainThread() -> Subscribe<Event> {
        return rawModify(subscribe: { (id, handler) in
            self.manual.subscribe(objectWith: id, with: { (event) in
                DispatchQueue.main.async { handler(event) }
            })
        }, entry: ProxyPayload.Entry.custom("main-thread"))
    }
    
    public func signed(with identifier: ObjectIdentifier?) -> SignedSubscribe<Event> {
        return map({ Signed.init($0, identifier) })
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

