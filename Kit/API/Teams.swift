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
    
    public let provider: ReadOnlyStorage<TeamsEndpoint, [String : Any]>
    public let all: Retrieve<Editioned<Teams>>
    public let fullTeam: ReadOnlyStorage<Team.ID, Editioned<Team.Full>>
    
    private let dataProvider: ReadOnlyStorage<APIPath, Data>
    
    public init(dataProvider: ReadOnlyStorage<APIPath, Data>) {
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
