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

// Alba - stateful event observing engine

public typealias EventHandler<Event> = (Event) -> ()

public protocol SignedProtocol {
    
    associatedtype Wrapped
    
    var value: Wrapped { get set }
    var submittedBy: ObjectIdentifier? { get set }
    
    init(_ signed: Signed<Wrapped>)
    
}

public struct Signed<Value> : SignedProtocol {
    public var value: Value
    public var submittedBy: ObjectIdentifier?
    
    public init(_ value: Value, _ submittedBy: ObjectIdentifier?) {
        self.value = value
        self.submittedBy = submittedBy
    }
    
    public func map<T>(_ transform: (Value) -> T) -> Signed<T> {
        return Signed<T>(transform(self.value), self.submittedBy)
    }
    
    public init(_ signed: Signed<Value>) {
        self = signed
    }
}

public extension ObjectIdentifier {
    
    func belongsTo(_ object: AnyObject) -> Bool {
        return ObjectIdentifier(object) == self
    }
    
}

public extension Optional where Wrapped == ObjectIdentifier {
    
    func belongsTo(_ object: AnyObject) -> Bool {
        if let wrapped = self {
            return ObjectIdentifier(object) == wrapped
        }
        return false
    }
    
}
