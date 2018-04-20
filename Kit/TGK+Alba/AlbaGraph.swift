
import Alba
import Foundation
import Shallows

public typealias AlbaObjectDescriptor = (label: String, type: Any.Type)

internal func publisherRepresentation(of objectDescriptor: AlbaObjectDescriptor) -> String {
    return "\(objectDescriptor.label) (\(objectDescriptor.type))"
}

internal func subscriberRepresentation(of objectDescriptor: AlbaObjectDescriptor) -> String {
    return "\(objectDescriptor.type):\(objectDescriptor.label)"
}

extension ProxyPayload.Entry.Subscription {
    
    var descriptor: AlbaObjectDescriptor {
        switch self {
        case .byObject(identifier: let identifier, ofType: let type):
            return (label: String(identifier.hashValue), type: type)
        case .listen(eventType: let type):
            return (label: "listener", type: type)
        case .redirection(to: let publisher, ofType: let type):
            return (label: publisher, type: type)
        }
    }
    
}

extension ProxyPayload {
    
    var publishers: [AlbaObjectDescriptor] {
        var publishersDescriptions: [AlbaObjectDescriptor] = []
        for entry in entries {
            switch entry {
            case .publisherLabel(let label, type: let type):
                publishersDescriptions.append((label, type))
            case .merged(label: _, otherPayload: let otherPayload):
                publishersDescriptions.append(contentsOf: otherPayload.publishers)
            default:
                continue
            }
        }
        return publishersDescriptions
    }
    
    var subscribers: [AlbaObjectDescriptor] {
        var descriptions: [AlbaObjectDescriptor] = []
        for entry in entries {
            switch entry {
            case .subscription(let subscription):
                descriptions.append(subscription.descriptor)
            default:
                continue
            }
        }
        return descriptions
    }
    
}

final public class AlbaCartographer {
    
    internal let graphAccessQueue = DispatchQueue(label: "com.Alba.AlbaCartographer.graphAccessQueue", qos: .background)
    internal let writeJSONQueue = DispatchQueue(label: "com.Alba.AlbaCartographer.writeJSONQueue", qos: .background)
    
    let _write: ([String : Any]) -> ()
    
    public init(write: @escaping ([String : Any]) -> ()) {
        self._write = write
    }
    
    internal var graph = AlbaGraph()
    
    public func enable() {
        Alba.InformBureau.didSubscribe.subscribe(self, with: AlbaCartographer.event_didSubscribe)
        print("Enabled AlbaCartographer")
    }
    
    internal func event_didSubscribe(_ payload: ProxyPayload) {
        graphAccessQueue.async {
            let publishers = payload.publishers.map(publisherRepresentation(of:))
            let newSubscribers = payload.subscribers.map(subscriberRepresentation(of:))
            for publisher in publishers {
                var subscribers = self.graph.connections[publisher] ?? []
                subscribers.append(contentsOf: newSubscribers)
                self.graph.connections[publisher] = subscribers
            }
        }
        writeJSONQueue.async {
            self.write()
        }
    }
    
    private func write() {
        let dict: [String : Any] = self.graphAccessQueue.sync {
            return (try? self.graph.map()) ?? [:]
        }
        self._write(dict)
    }
    
    public func syncWrite() {
        writeJSONQueue.sync {
            self.write()
        }
    }
    
    public func logGraph() {
        graphAccessQueue.sync {
            _ = dump(graph)
        }
    }
    
}

public extension AlbaCartographer {
    
    convenience init(writeTo url: URL) {
        self.init { dict in
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
                try jsonData.write(to: url)
            } catch {
                print("(Alba.Graph) Cannot write json, error: \(error)")
            }
        }
    }
    
    convenience init<Writable : WritableStorageProtocol>(writingTo cache: Writable) where Writable.Key == Void, Writable.Value == [String : Any] {
        self.init { (dict) in
            cache.set(dict, completion: { (result) in
                if let error = result.error {
                    print("(Alba.Graph) Cannot write json, error: \(error)")
                } else {
                    print("Did wrote JSON")
                }
            })
        }
    }
    
}

struct AlbaGraph {
    
    var connections: [String : [String]] = [:]
    
}

extension AlbaGraph : OutMappable {
    
    typealias MappingKeys = String
    
    func outMap<Destination>(mapper: inout OutMapper<Destination, String>) throws {
        for (publisher, subscribers) in connections {
            try mapper.map(subscribers, to: publisher)
        }
    }
    
}
