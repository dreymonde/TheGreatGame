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
    
    public let path: String
    
    init(path: String) {
        self.path = "teams/\(path)"
    }
    
    public static let all = TeamsEndpoint(path: "all.json")
    public static func fullTeam(withID id: Team.ID) -> TeamsEndpoint {
        return TeamsEndpoint(path: "\(id.rawID).json")
    }
    
}

public final class TeamsAPI {
    
    public let provider: ReadOnlyCache<TeamsEndpoint, [String : Any]>
    public let all: ReadOnlyCache<Void, Editioned<Teams>>
    public let fullTeam: ReadOnlyCache<Team.ID, Editioned<Team.Full>>
    
    private let github: GitHubRepoCache
    
    public init(networkCache: ReadOnlyCache<URL, Data>) {
        self.github = GitHubRepoCache(owner: "dreymonde", repo: "TheGreatGameStorage", networkCache: networkCache)
        self.provider = github
            .makeReadOnly()
            .mapJSONDictionary()
            .mapKeys({ $0.path })
        self.all = provider
            .singleKey(.all)
            .mapMappable(of: Editioned<Teams>.self)
        self.fullTeam = provider
            .mapMappable(of: Editioned<Team.Full>.self)
            .mapKeys({ .fullTeam(withID: $0) })
    }
    
    public convenience init() {
        let urlSessionCache = URLSession(configuration: .default)
            .makeReadOnly()
            .droppingResponse()
            .usingURLKeys()
        self.init(networkCache: urlSessionCache)
    }
    
}
