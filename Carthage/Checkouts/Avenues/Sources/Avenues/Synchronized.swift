import Foundation

internal struct Synchronized<Value> {
    
    private var _value: Value
    private let queue = DispatchQueue(label: "com.avenues.synchronized-\(Value.self)", attributes: [.concurrent])
    
    init(_ value: Value) {
        self._value = value
    }
    
    func read() -> Value {
        return queue.sync { _value }
    }
    
    mutating func write(with modify: (inout Value) -> ()) {
        queue.sync(flags: .barrier) {
            modify(&_value)
        }
    }
    
    @discardableResult
    mutating func transaction<Return>(with modify: (inout Value) -> (Return)) -> Return {
        return queue.sync(flags: .barrier) {
            return modify(&_value)
        }
    }
    
    mutating func write(_ newValue: Value) {
        queue.sync(flags: .barrier) {
            _value = newValue
        }
    }
    
}
