//
//  Teams.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Shallows
import Foundation

public struct TeamsEndpoint {
    
    public let path: APIPath
    
    init(path: APIPath) {
        self.path = "teams" + path
    }
    
    public static let all = TeamsEndpoint(path: "all.json")
    public static func fullTeam(withID id: Team.ID) -> TeamsEndpoint {
        return TeamsEndpoint(path: APIPath(rawValue: "\(id.rawID).json"))
    }
    
}

public final class TeamsAPI : APIPoint {
    
    public let provider: ReadOnlyCache<TeamsEndpoint, [String : Any]>
    public let all: Retrieve<Editioned<Teams>>
    public let fullTeam: ReadOnlyCache<Team.ID, Editioned<Team.Full>>
    
    private let dataProvider: ReadOnlyCache<APIPath, Data>
    
    public init(dataProvider: ReadOnlyCache<APIPath, Data>) {
        self.dataProvider = dataProvider
        self.provider = dataProvider
            .mapJSONDictionary()
            .mapKeys({ $0.path })
        self.all = provider
            .singleKey(.all)
            .mapMappable(of: Editioned<Teams>.self)
        self.fullTeam = provider
            .mapMappable(of: Editioned<Team.Full>.self)
            .mapKeys({ .fullTeam(withID: $0) })
    }
        
}

public final class TeamsAPICache : APICachePoint {
    
    public let provider: Cache<TeamsEndpoint, [String : Any]>
    public let all: Cache<Void, Editioned<Teams>>
    public let fullTeam: Cache<Team.ID, Editioned<Team.Full>>
    
    private let dataProvider: Cache<APIPath, Data>
    
    public init(dataProvider: Cache<APIPath, Data>) {
        self.dataProvider = dataProvider
        self.provider = dataProvider
            .mapJSONDictionary()
            .mapKeys({ $0.path })
        self.all = provider
            .singleKey(.all)
            .mapMappable(of: Editioned<Teams>.self)
        self.fullTeam = provider
            .mapMappable(of: Editioned<Team.Full>.self)
            .mapKeys({ .fullTeam(withID: $0) })
    }
    
}
