//
//  APIPath.swift
//  WebAPI
//
//  Created by Олег on 08.08.17.
//
//

import Foundation

public struct APIPath : RawRepresentable, Hashable, ExpressibleByStringLiteral {
    
    public static let separator = "/"
    
    public typealias RawValue = String
    
    public var rawValue: String
    
    public var components: [String] {
        return rawValue.components(separatedBy: APIPath.separator)
    }
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(components: [String]) {
        self.rawValue = components.joined(separator: APIPath.separator)
    }
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.rawValue = value
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.rawValue = value
    }
    
}

extension APIPath : ExpressibleByArrayLiteral {
    
    public typealias Element = APIPath
    
    public init(arrayLiteral elements: Element...) {
        self.init(components: elements.map({ $0.rawValue }))
    }
    
}

extension APIPath {
    
    public static func + (lhs: APIPath, rhs: APIPath) -> APIPath {
        return APIPath(components: [lhs.rawValue, rhs.rawValue])
    }
    
}

extension URL {
    
    public func appendingPath(_ path: APIPath) -> URL {
        return appendingPathComponent(path.rawValue)
    }
    
}
