import Foundation

precedencegroup Apply {
    associativity: left
    lowerThan: AdditionPrecedence
}

infix operator <* : Apply

func <* <T, V> (lhs: T, rhs: (T) -> V) -> V {
    return rhs(lhs)
}

public func apply<T, V>(to value: T, _ function: (T) -> V) -> V {
    return function(value)
}

infix operator <-

func modified<T>(_ value: T, modify: (inout T) -> Void) -> T {
    var copy = value
    modify(&copy)
    return copy
}

@discardableResult
func <- <T : AnyObject>(value: T, modify: (T) -> Void) -> T {
    modify(value)
    return value
}

func printed<T>(_ value: T) -> T {
    print(value)
    return value
}

func fault(_ info: Any) {
    print("UNEXPECTED : \(info)")
}

func printWithContext(_ string: String? = nil, file: String = #file, line: UInt = #line, function: StaticString = #function) {
    #if DEBUG
        let str = string != nil ? " --> \(string!)" : ""
        print("\((file as NSString).lastPathComponent): \(function): \(line)\(str)")
    #endif
}

func logged<T>(_ value: T, _ message: String) -> T {
    print(value, message)
    return value
}

func jprint<T>(_ value: T) {
    print(value)
}

func jdump<T>(_ value: T) {
    dump(value)
}

@available(*, deprecated, message: "Unimplemented code")
var later: Never {
    fatalError("Unimplemented")
}

func runtimeInject<In, Out>(_ input: In) -> Out {
    fatalError("Should inject")
}

public extension String {
    
    #if DEBUG
    var unlocalized: String {
        return self
    }
    #else
    @available(*, deprecated, message: "You should not use unlocalized strings in release builds")
    var unlocalized: String {
        return self
    }
    #endif
    
}

extension Bool {
    
    var not: Bool {
        return !self
    }
    
}
