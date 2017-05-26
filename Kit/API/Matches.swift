//
//  Matches.swift
//  TheGreatGame
//
//  Created by Олег on 05.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public struct MatchesEndpoint {
    
    public let path: String
    
    init(path: String) {
        self.path = "matches/\(path)"
    }
    
    public static let all = MatchesEndpoint(path: "all.json")
    public static func fullMatch(withID id: Team.ID) -> MatchesEndpoint {
        return MatchesEndpoint(path: "\(id.rawID).json")
    }
    public static let stages = MatchesEndpoint(path: "stages.json")
    
}

public final class MatchesAPI : APIPoint {
    
    public let provider: ReadOnlyCache<MatchesEndpoint, [String : Any]>
    public let all: ReadOnlyCache<Void, Editioned<Matches>>
    public let stages: ReadOnlyCache<Void, Editioned<Stages>>
    
    private let dataProvider: ReadOnlyCache<String, Data>
    
    public init(dataProvider: ReadOnlyCache<String, Data>) {
        self.dataProvider = dataProvider
        self.provider = dataProvider
            .mapJSONDictionary()
            .mapKeys({ $0.path })
        self.all = provider
            .singleKey(.all)
            .mapMappable(of: Editioned<Matches>.self)
        self.stages = provider
            .singleKey(.stages)
            .mapMappable()
    }
        
}

public final class MatchesAPICache : APICachePoint {
    
    public let provider: Cache<MatchesEndpoint, [String : Any]>
    public let all: Cache<Void, Editioned<Matches>>
    public let stages: Cache<Void, Editioned<Stages>>
    
    private let dataProvider: Cache<String, Data>
    
    init(dataProvider: Cache<String, Data>) {
        self.dataProvider = dataProvider
        self.provider = dataProvider
            .mapJSONDictionary()
            .mapKeys({ $0.path })
        self.all = provider
            .singleKey(.all)
            .mapMappable()
        self.stages = provider
            .singleKey(.stages)
            .mapMappable()
    }
    
}
