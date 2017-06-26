//
//  TeamFull.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

extension Team {

    public struct Full {
        
        public let id: ID
        public let name: String
        public let shortName: String
        public let rank: Int
        public let badges: Badges
        public let group: Group.Compact
        public let matches: [Match.Compact]
        public let summary: String
        
    }
    
    public struct Badges {
        public let large: URL
        public let flag: URL
    }
    
}

extension Team.Full : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case name
        case short_name
        case id
        case rank
        case badges
        case group
        case matches
        case summary
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
//        print(mapper.source)
        self.name = try mapper.map(from: .name)
        self.shortName = try mapper.map(from: .short_name)
        self.id = try mapper.map(from: .id)
        self.rank = try mapper.map(from: .rank)
        self.badges = try mapper.map(from: .badges)
        self.group = try mapper.map(from: .group)
        self.matches = try mapper.map(from: .matches)
        self.summary = try mapper.map(from: .summary)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.shortName, to: .short_name)
        try mapper.map(self.id, to: .id)
        try mapper.map(self.rank, to: .rank)
        try mapper.map(self.badges, to: .badges)
        try mapper.map(self.group, to: .group)
        try mapper.map(self.matches, to: .matches)
        try mapper.map(self.summary, to: .summary)
    }
    
}

extension Team.Badges : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case large, flag
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.large = try mapper.map(from: .large)
        self.flag = try mapper.map(from: .flag)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.large, to: .large)
        try mapper.map(self.flag, to: .flag)
    }
    
}
