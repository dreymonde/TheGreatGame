/**
 *  Alba
 *
 *  Copyright (c) 2016 Oleg Dreyman. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

@available(*, unavailable, renamed: "Subscribe")
public typealias PublisherProxy<T> = Subscribe<T>

public struct ProxyPayload : InformBureauPayload {
    
    public enum Entry {
        
        public enum Subscription {
            case byObject(identifier: ObjectIdentifier, ofType: Any.Type)
            case redirection(to: String, ofType: Any.Type)
            case listen(eventType: Any.Type)
        }
        
        public enum Transformation {
            case sameType
            case transformed(fromType: Any.Type, toType: Any.Type)
        }
        
        public typealias TransformationLabel = String
        
        public enum MergeLabel {
            case merged
            case custom(String)
        }
        
        case publisherLabel(String, type: Any.Type)
        case subscription(Subscription)
        case transformation(label: TransformationLabel, Transformation)
        case merged(label: MergeLabel, otherPayload: ProxyPayload)
        case custom(String)
        
    }
    
    public var entries: [Entry]
    
    public init(entries: [Entry]) {
        self.entries = entries
    }
    
}

public extension ProxyPayload.Entry {
    
    static var filtered: ProxyPayload.Entry {
        return .transformation(label: "filtered", .sameType)
    }
    
    static func mapped(fromType: Any.Type, toType: Any.Type) -> ProxyPayload.Entry {
        return .transformation(label: "mapped", .transformed(fromType: fromType, toType: toType))
    }
    
    static var interrupted: ProxyPayload.Entry {
        return .custom("interrupted")
    }
    
    static let emptyProxyLabel = "WARNING: Empty proxy"
    
}

public struct Subscribe<Event> {
    
    fileprivate let _subscribe: (ObjectIdentifier, @escaping EventHandler<Event>) -> ()
    fileprivate let _unsubscribe: (ObjectIdentifier) -> ()
    internal let payload: ProxyPayload
    
    public init(subscribe: @escaping (ObjectIdentifier, @escaping EventHandler<Event>) -> (),
                unsubscribe: @escaping (ObjectIdentifier) -> (),
                label: String = "unnnamed") {
        self._subscribe = subscribe
        self._unsubscribe = unsubscribe
        self.payload = ProxyPayload.empty.adding(entry: .publisherLabel(label, type: Subscribe<Event>.self))
    }
    
    public init(subscribe: @escaping (ObjectIdentifier, @escaping EventHandler<Event>) -> (),
                  unsubscribe: @escaping (ObjectIdentifier) -> (),
                  payload: ProxyPayload) {
        self._subscribe = subscribe
        self._unsubscribe = unsubscribe
        self.payload = payload
    }
    
//    public var signed: SignedSubscribe<Event> {
//        return SignedSubscribe<Event>(subscribe: { (identifier, handler) in
//            self._subscribe(identifier, unsigned(handler))
//        }, unsubscribe: self._unsubscribe)
//    }
    
    public func subscribe<Object : AnyObject>(_ object: Object,
                          with producer: @escaping (Object) -> EventHandler<Event>) {
        let identifier = ObjectIdentifier(object)
        if InformBureau.isEnabled, Object.self != Publisher<Event>.self {
            let entry = ProxyPayload.Entry.subscription(.byObject(identifier: identifier, ofType: Object.self))
            InformBureau.submitSubscription(payload.adding(entry: entry))
        }
        self._subscribe(identifier, { [weak object] in
            if let object = object {
                producer(object)($0)
            } else {
                self._unsubscribe(identifier)
            }
        })
    }
    
    public func flatSubscribe<Object : AnyObject>(_ object: Object, with handler: @escaping (Object, Event) -> ()) {
        subscribe(object, with: unfold(handler))
    }
    
    public func rawModify<OtherEvent>(subscribe: @escaping (ObjectIdentifier, @escaping EventHandler<OtherEvent>) -> (),
                             entry: ProxyPayload.Entry) -> Subscribe<OtherEvent> {
        return Subscribe<OtherEvent>(subscribe: subscribe,
                                     unsubscribe: self._unsubscribe,
                                     payload: payload.adding(entry: entry))
    }
    
    public func filter(_ condition: @escaping (Event) -> Bool) -> Subscribe<Event> {
        return rawModify(subscribe: { (identifier, handle) in
            let handler: EventHandler<Event> = { event in
                if condition(event) { handle(event) }
            }
            self._subscribe(identifier, handler)
        }, entry: .filtered)
    }
    
    public func map<OtherEvent>(_ transform: @escaping (Event) -> OtherEvent) -> Subscribe<OtherEvent> {
        return rawModify(subscribe: { (identifier, handle) in
            let handler: EventHandler<Event> = { event in
                handle(transform(event))
            }
            self._subscribe(identifier, handler)
        }, entry: .mapped(fromType: Event.self,
                          toType: OtherEvent.self))
    }
    
    public func flatMap<OtherEvent>(_ transform: @escaping (Event) -> OtherEvent?) -> Subscribe<OtherEvent> {
        return rawModify(subscribe: { (identifier, handle) in
            let handler: EventHandler<Event> = { event in
                if let transformed = transform(event) { handle(transformed) }
            }
            self._subscribe(identifier, handler)
        }, entry: .mapped(fromType: Event.self,
                          toType: OtherEvent.self))
    }
    
    public func interrupted(with work: @escaping (Event) -> ()) -> Subscribe<Event> {
        return rawModify(subscribe: { (identifier, handle) in
            self._subscribe(identifier, { work($0); handle($0) })
        }, entry: .interrupted)
    }
    
    public func merged(with other: Subscribe<Event>) -> Subscribe<Event> {
        return Subscribe<Event>(subscribe: { (identifier, handle) in
            self._subscribe(identifier, handle)
            other._subscribe(identifier, handle)
        }, unsubscribe: { (identifier) in
            self._unsubscribe(identifier)
            other._unsubscribe(identifier)
        }, payload: payload.adding(entry: .merged(label: .merged, otherPayload: other.payload)))
    }
    
    public func redirect<Publisher : PublisherProtocol>(to publisher: Publisher) where Publisher.Event == Event {
        if InformBureau.isEnabled {
            InformBureau.submitSubscription(payload.adding(entry: .subscription(.redirection(to: publisher.label, ofType: Publisher.self))))
        }
        subscribe(publisher, with: Publisher.publish)
    }
    
    public func listen(with handler: @escaping EventHandler<Event>) {
        let listener = NotGoingBasicListener<Event>(subscribingTo: self, handler)
        _silenceWarning(of: listener)
        if InformBureau.isEnabled {
            InformBureau.submitSubscription(payload.adding(entry: .subscription(.listen(eventType:Event.self))))
        }
    }
    
    public func void() -> Subscribe<Void> {
        return map({ _ in })
    }
    
    public var manual: ManualSubscribe<Event> {
        return ManualSubscribe(proxy: self)
    }
    
}

public struct ManualSubscribe<Event> {
    
    fileprivate let proxy: Subscribe<Event>
    
    public func subscribe(_ object: AnyObject, with subscription: @escaping EventHandler<Event>) {
        let identifier = ObjectIdentifier(object)
        proxy._subscribe(identifier, subscription)
    }
    
    public func unsubscribe(_ object: AnyObject) {
        let identifier = ObjectIdentifier(object)
        proxy._unsubscribe(identifier)
    }
    
    public func subscribe(objectWith objectIdentifier: ObjectIdentifier,
                          with handler: @escaping EventHandler<Event>) {
        proxy._subscribe(objectIdentifier, handler)
    }
    
    public func unsubscribe(objectWith objectIdentifier: ObjectIdentifier) {
        proxy._unsubscribe(objectIdentifier)
    }
    
}

public extension Subscribe where Event : SignedProtocol {
    
    public func subscribe<Object : AnyObject>(_ object: Object,
                          with producer: @escaping (Object) -> EventHandler<(Event.Wrapped, submitterIdentifier: ObjectIdentifier?)>) {
        let identifier = ObjectIdentifier(object)
        self._subscribe(identifier, { [weak object] event in
            if let object = object {
                let handler = producer(object)
                handler((event.value, event.submittedBy))
            } else {
                self._unsubscribe(identifier)
            }
        })
    }
    
    public func subscribe<Object : AnyObject>(_ object: Object,
                          with producer: @escaping (Object) -> EventHandler<(Event.Wrapped, submittedBySelf: Bool)>) {
        let identifier = ObjectIdentifier(object)
        self._subscribe(identifier, { [weak object] event in
            if let object = object {
                let handler = producer(object)
                handler((event.value, event.submittedBy == identifier))
            } else {
                self._unsubscribe(identifier)
            }
        })
    }
    
    func filterValue(_ condition: @escaping (Event.Wrapped) -> Bool) -> Subscribe<Event> {
        return filter({ condition($0.value) })
    }
    
    func drop<Object : AnyObject>(eventsSignedBy signer: Object) -> Subscribe<Event> {
        return weak(signer).filter({ (object) in
            return { (event) in
                !event.submittedBy.belongsTo(object)
            }
        }).proxy
    }
    
    func mapValue<OtherEvent>(_ transform: @escaping (Event.Wrapped) -> OtherEvent) -> Subscribe<Signed<OtherEvent>> {
        return map({ (event) in
            let transformed = transform(event.value)
            let signed = Signed.init(transformed, event.submittedBy)
            return signed
        })
    }
    
    func flatMapValue<OtherEvent>(_ transform: @escaping (Event.Wrapped) -> OtherEvent?) -> Subscribe<Signed<OtherEvent>> {
        return flatMap({ (event) in
            let transformed = transform(event.value)
            let signed = transformed.map({ Signed.init($0, event.submittedBy) })
            return signed
        })
    }
    
    var unsigned: Subscribe<Event.Wrapped> {
        return self.map({ $0.value })
    }
    
}

public extension Subscribe {
    
    static func empty() -> Subscribe<Event> {
        let payload = ProxyPayload.empty.adding(entry: .publisherLabel(ProxyPayload.Entry.emptyProxyLabel, type: Subscribe<Event>.self))
        return Subscribe<Event>(subscribe: { _,_  in },
                                     unsubscribe: { _ in },
                                     payload: payload)
    }
    
}

public extension Subscribe {
    
    func weak<Object : AnyObject>(_ object: Object) -> WeakSubscribe<Object, Event> {
        return WeakSubscribe(proxy: self, object: object)
    }
    
}

public typealias SignedSubscribe<Event> = Subscribe<Signed<Event>>

fileprivate func _silenceWarning(of unused: Any) {
    
}
