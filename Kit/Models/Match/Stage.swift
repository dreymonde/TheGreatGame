//
//  Stage.swift
//  TheGreatGame
//
//  Created by Олег on 10.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public struct Stage : Model {
    
    public let title: String
    public var matches: [Match.Compact]
    
}

extension Stage : CustomStringConvertible {
    
    public var description: String {
        return "Stage: \(title), \(matches)"
    }
    
}

extension Stage : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case title, matches
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.title = try mapper.map(from: .title)
        self.matches = try mapper.map(from: .matches)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.title, to: .title)
        try mapper.map(self.matches, to: .matches)
    }
    
}

public struct Stages : Model {
    
    public let stages: [Stage]
    
}

extension Stages : ArrayMappableBox {
    
    public init(_ values: [Stage]) {
        self.stages = values
    }
    
    public var values: [Stage] {
        return stages
    }
    
}

extension Stage : MappableBoxable {
    
    public typealias Box = Stages
    
}

extension Stages : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case stages
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.stages = try mapper.map(from: .stages)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.stages, to: .stages)
    }
    
}
