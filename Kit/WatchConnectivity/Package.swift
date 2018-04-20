//
//  Package.swift
//  TheGreatGame
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

#if os(iOS)
    public typealias Connection = WatchSessionManager
#else
    public typealias Connection = Phone
#endif

extension Connection {
    
    public struct Package {
        
        public enum Kind : String {
            case favorite_teams
            case favorite_matches
            case complication_match_update
        }
        
        public let kind: Kind
        public let content: [String : Any]
        
    }
    
}

extension Connection.Package : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case kind, content
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.kind = try mapper.map(from: .kind)
        self.content = try mapper.unsafe_map(from: .content)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.kind, to: .kind)
        try mapper.unsafe_map(self.content, to: .content)
    }
    
}

public protocol AppleWatchPackableElement  {
    
    static var kind: Connection.Package.Kind { get }
    
}

public protocol AppleWatchPackable : AppleWatchPackableElement, Mappable {
    
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

extension Match.Full : AppleWatchPackable {
    
    public static var kind: Connection.Package.Kind {
        return .complication_match_update
    }
    
}

extension FavoriteTeams : AppleWatchPackableElement {
    
    public static var kind: Connection.Package.Kind {
        return .favorite_teams
    }
    
}

extension FavoriteMatches : AppleWatchPackableElement {
    
    public static var kind: Connection.Package.Kind {
        return .favorite_matches
    }
    
}

public struct IDPackage<Flag : FlagDescriptor> : AppleWatchPackable where Flag : AppleWatchPackableElement {
    
    public static var kind: Connection.Package.Kind {
        return Flag.kind
    }
    
    public let favs: Set<Flag.IDType>
    
    public init(_ favs: FlagSet<Flag>) {
        self.favs = favs.set
    }
    
}

extension IDPackage {
    
    public static var packageToIDsSet: AlbaAdapter<Connection.Package, FlagSet<Flag>> {
        return { proxy in
            proxy
                .filter({ $0.kind == Flag.kind })
                .flatMap({ try? IDPackage.unpacked(from: $0) })
                .map({ FlagSet($0.favs) })
        }
    }
    
}

extension IDPackage : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case favorites
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.favs = Set(try mapper.map(from: .favorites))
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(Array(favs), to: .favorites)
    }
    
}
