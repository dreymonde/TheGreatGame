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
    public static func fullTeam(withID id: Team.ID) -> MatchesEndpoint {
        return MatchesEndpoint(path: "\(id.rawID).json")
    }
    
}

public final class MatchesAPI : APIPoint {
    
    public let provider: ReadOnlyCache<MatchesEndpoint, [String : Any]>
    public let all: ReadOnlyCache<Void, Editioned<Matches>>
    
    private let dataProvider: ReadOnlyCache<String, Data>
    
    public init(rawDataProvider: ReadOnlyCache<String, Data>) {
        self.dataProvider = rawDataProvider
        self.provider = rawDataProvider
            .makeReadOnly()
            .mapJSONDictionary()
            .mapKeys({ $0.path })
        self.all = provider
            .singleKey(.all)
            .mapMappable(of: Editioned<Matches>.self)
    }
        
}
