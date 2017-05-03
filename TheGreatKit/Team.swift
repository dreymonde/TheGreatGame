//
//  Team.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

public struct Team {

    public let id: Int
    public let name: String
    public let shortName: String
    public let rank: Int
    public let badgeURL: URL
    
}

extension Team : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case name
        case short_name
        case id
        case rank
        case badge_url
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.name = try mapper.map(from: .name)
        self.shortName = try mapper.map(from: .short_name)
        self.id = try mapper.map(from: .id)
        self.rank = try mapper.map(from: .rank)
        self.badgeURL = try mapper.map(from: .badge_url)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.shortName, to: .short_name)
        try mapper.map(self.id, to: .id)
        try mapper.map(self.rank, to: .rank)
        try mapper.map(self.badgeURL, to: .badge_url)
    }
    
}

public struct Teams {
    
    public var teams: [Team]
    
}

extension Teams : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case teams
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.teams = try mapper.map(from: .teams)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.teams, to: .teams)
    }
    
}
