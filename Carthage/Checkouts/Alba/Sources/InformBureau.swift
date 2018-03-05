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

public protocol InformBureauPayload {
    
    associatedtype Entry
    
    init(entries: [Entry])
    
    var entries: [Entry] { get set }
    
}

public extension InformBureauPayload {
    
    func adding(entry: @autoclosure () -> Entry) -> Self {
        if InformBureau.isEnabled {
            var updatedEntries = entries
            updatedEntries.append(entry())
            return Self(entries: updatedEntries)
        } else {
            return .empty
        }
    }
    
    static var empty: Self {
        return Self(entries: [])
    }
    
}

fileprivate final class InformBureauPublisher<Event> : Subscribable {
    
    var handlers: [EventHandler<Event>] = []
    
    func publish(_ event: Event) {
        handlers.forEach({ $0(event) })
    }
    
    fileprivate var proxy: Subscribe<Event> {
        let payload = ProxyPayload.empty.adding(entry: .publisherLabel("Alba.InformBureau", type: InformBureauPublisher<Event>.self))
        return Subscribe(subscribe: { (_, handler) in self.handlers.append(handler) },
                              unsubscribe: { _ in },
                              payload: payload)
    }
    
}

public final class InformBureau {
    
    public typealias SubscriptionLogMessage = ProxyPayload
    public typealias PublishingLogMessage = PublishingPayload
    public typealias GeneralWarningLogMessage = String
    
    public static var isEnabled = false
        
    fileprivate static let subscriptionPublisher = InformBureauPublisher<SubscriptionLogMessage>()
    public static var didSubscribe: Subscribe<SubscriptionLogMessage> {
        return subscriptionPublisher.proxy
    }
    
    fileprivate static let publishingPublisher = InformBureauPublisher<PublishingLogMessage>()
    public static var didPublish: Subscribe<PublishingLogMessage> {
        return publishingPublisher.proxy
    }
    
    fileprivate static let generalWarningsPublisher = InformBureauPublisher<GeneralWarningLogMessage>()
    public static var generalWarnings: Subscribe<GeneralWarningLogMessage> {
        return generalWarningsPublisher.proxy
    }
    
    static func submitSubscription(_ logMessage: SubscriptionLogMessage) {
        subscriptionPublisher.publish(logMessage)
    }
    
    static func submitPublishing(_ logMessage: PublishingLogMessage) {
        publishingPublisher.publish(logMessage)
    }
    
    static func submitGeneralWarning(_ logMessage: GeneralWarningLogMessage) {
        generalWarningsPublisher.publish(logMessage)
    }
    
    public final class Logger {
        
        static let shared = Logger()
        
        private init() { }
        
        public static func enable() {
            if !InformBureau.isEnabled {
                print("Enabling Alba.InformBureau...")
                InformBureau.isEnabled = true
            }
            InformBureau.didSubscribe.subscribe(shared, with: Logger.logSubMergeLevelZero)
            InformBureau.didPublish.subscribe(shared, with: Logger.logPub)
            InformBureau.generalWarnings.subscribe(shared, with: Logger.logGeneralWarning)
        }
        
        public static func disable() {
            InformBureau.didSubscribe.manual.unsubscribe(shared)
            InformBureau.didPublish.manual.unsubscribe(shared)
            InformBureau.generalWarnings.manual.unsubscribe(shared)
        }
        
        func logSubMergeLevelZero(_ logMessage: SubscriptionLogMessage) {
            logSub(logMessage)
            print("")
        }
        
        func logSub(_ logMessage: SubscriptionLogMessage, mergeLevel: Int = 0) {
            var mergeInset = ""
            (0 ..< mergeLevel).forEach { (_) in
                mergeInset += "   "
            }
            let mark = "(S) " + mergeInset
            func mprint(_ item: String) {
                print(mark + item)
            }
            if mergeLevel == 0 {
                print("")
            }
            for entry in logMessage.entries {
                switch entry {
                case .publisherLabel(let label, let type):
                    mprint("\(label) (\(type))")
                case .transformation(let label, let transformation):
                    
                    switch transformation {
                    case .sameType:
                        mprint("--> \(label)")
                    case .transformed(let fromType, let toType):
                        mprint("--> \(label) from \(fromType) to \(toType)")
                    }
                case .custom(let custom):
                    mprint("--> \(custom)")
                case .merged(let label, let otherPayload):
                    mprint("\(label) with:")
                    logSub(otherPayload, mergeLevel: mergeLevel + 1)
                case .subscription(let subscription):
                    switch subscription {
                    case .byObject(let identifier, let type):
                        mprint("!-> subscribed by \(type):\(identifier.hashValue)")
                    case .redirection(let label, let type):
                        mprint("!-> redirected to \(label) (\(type))")
                    case .listen(let type):
                        mprint("!-> listened with EventHandler<\(type)>")
                    }
                }
            }
        }
        
        func logPub(_ logMessage: PublishingLogMessage) {
            let mark = "(P) "
            print("")
            for entry in logMessage.entries {
                switch entry {
                case .published(publisherLabel: let publisherLabel, publisherType: let publisherType, event: let event):
                    print(mark + "\(publisherLabel) (\(publisherType)) published \(event)")
                case .handled(handlerLabel: let handlerLabel):
                    print(mark + "--> handled by \(handlerLabel)")
                }
            }
        }
        
        func logGeneralWarning(_ logMessage: GeneralWarningLogMessage) {
            print("")
            print("(W) \(logMessage)")
        }
        
    }
    
}
