
public enum ProcessorResult<Value> {
    case success(Value)
    case failure(Error)
}

public typealias ProcessorCompletion<T> = (ProcessorResult<T>) -> ()

public protocol ProcessorProtocol {
    
    associatedtype Key
    associatedtype Value
    
    func start(key: Key, completion: @escaping ProcessorCompletion<Value>)
    func cancel(key: Key)
    func cancelAll()
    
}

public extension ProcessorProtocol {
    
    func asProcessor() -> Processor<Key, Value> {
        return Processor(self)
    }
    
    func mapKeys<OtherKey>(to keyType: OtherKey.Type = OtherKey.self,
                           _ transform: @escaping (OtherKey) -> Key) -> Processor<OtherKey, Value> {
        let start: Processor<OtherKey, Value>.Start = { otherKey, completion in self.start(key: transform(otherKey), completion: completion) }
        let cancel: Processor<OtherKey, Value>.Cancel = { otherKey in self.cancel(key: transform(otherKey)) }
        return Processor(start: start,
                         cancel: cancel,
                         cancelAll: cancelAll)
    }
    
    func mapValues<OtherValue>(to valueType: OtherValue.Type = OtherValue.self,
                               _ transform: @escaping (Value) throws -> OtherValue) -> Processor<Key, OtherValue> {
        let start: Processor<Key, OtherValue>.Start = { key, completion in
            self.start(key: key, completion: { (result) in
                switch result {
                case .success(let value):
                    do {
                        let otherValue = try transform(value)
                        completion(.success(otherValue))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            })
        }
        return Processor(start: start,
                         cancel: self.cancel(key:),
                         cancelAll: self.cancelAll)
    }
    
}

public struct Processor<Key, Value> : ProcessorProtocol {
    
    public typealias Start = (Key, @escaping ProcessorCompletion<Value>) -> ()
    public typealias Cancel = (Key) -> ()
    public typealias CancelAll = () -> ()
    
    private struct Implementation {
        let start: Processor.Start
        let cancel: Processor.Cancel
        let cancelAll: Processor.CancelAll
    }
    
    private let implementation: Implementation
    
    public init(start: @escaping Processor.Start,
                cancel: @escaping Processor.Cancel,
                cancelAll: @escaping Processor.CancelAll) {
        self.implementation = Implementation(start: start,
                                             cancel: cancel,
                                             cancelAll: cancelAll)
    }
    
    public init<ProcessorType : ProcessorProtocol>(_ processor: ProcessorType) where ProcessorType.Key == Key, ProcessorType.Value == Value {
        self.init(start: processor.start,
                  cancel: processor.cancel,
                  cancelAll: processor.cancelAll)
    }
    
    public func start(key: Key, completion: @escaping (ProcessorResult<Value>) -> ()) {
        implementation.start(key, completion)
    }
    
    public func cancel(key: Key) {
        implementation.cancel(key)
    }
    
    public func cancelAll() {
        implementation.cancelAll()
    }
    
}
