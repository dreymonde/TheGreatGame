//
//  Group.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public enum Group {
    
    public struct Team {
        
        public let id: TheGreatKit.Team.ID
        public let name: String
        public let points: Int
        public let badges: TheGreatKit.Team.Badges
        
    }
    
    public struct Compact {
    
        public let title: String
        public let teams: [Team]
        
    }
    
}

public struct Groups {
    
    public let groups: [Group.Compact]
    
}

extension Group.Team : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case id, position, name, points, badges, summary
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.id = try mapper.map(from: .id)
        self.name = try mapper.map(from: .name)
        self.points = try mapper.map(from: .points)
        self.badges = try mapper.map(from: .badges)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.id, to: .id)
        try mapper.map(self.name, to: .name)
        try mapper.map(self.points, to: .points)
        try mapper.map(self.badges, to: .badges)
    }
    
}

extension Group.Compact : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case title, teams
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws where Source : InMap {
        self.title = try mapper.map(from: .title)
        self.teams = try mapper.map(from: .teams)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws where Destination : OutMap {
        try mapper.map(self.title, to: .title)
        try mapper.map(self.teams, to: .teams)
    }
    
}

extension Groups : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case groups
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws where Source : InMap {
        self.groups = try mapper.map(from: .groups)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws where Destination : OutMap {
        try mapper.map(self.groups, to: .groups)
    }
    
}
