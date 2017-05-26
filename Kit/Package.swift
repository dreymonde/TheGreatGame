//
//  Package.swift
//  TheGreatGame
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

#if os(iOS)
    public typealias Connection = AppleWatch
#else
    public typealias Connection = Phone
#endif

extension Connection {
    
    public struct Package {
        
        public enum Kind : String {
            case favorites
        }
        
        public let kind: Kind
        public let content: [String : Any]
        
    }
    
}

extension Connection.Package : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case kind, content
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.kind = try mapper.map(from: .kind)
        self.content = try mapper.unsafe_map(from: .content)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.kind, to: .kind)
        try mapper.unsafe_map(self.content, to: .content)
    }
    
}

public protocol AppleWatchPackable : Mappable {
    
    static var kind: Connection.Package.Kind { get }
    
    func pack() throws -> Connection.Package
    static func unpacked(from package: Connection.Package) throws -> Self
    
}

extension AppleWatchPackable {
    
    public func pack() throws -> Connection.Package {
        return Connection.Package(kind: Self.kind, content: try self.map())
    }
    
    public static func unpacked(from package: Connection.Package) throws -> Self {
        return try Self.init(from: package.content)
    }
    
}

public struct FavoritesPackage {
    
    public let favs: Set<Team.ID>
    
}

extension FavoritesPackage : AppleWatchPackable {
    
    public enum MappingKeys : String, IndexPathElement {
        case favorites
    }
    
    public static var kind: Connection.Package.Kind {
        return .favorites
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.favs = Set(try mapper.map(from: .favorites))
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(Array(favs), to: .favorites)
    }
    
}
