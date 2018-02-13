//
//  TodayExtension.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import TheGreatKit
import Avenues
import Alba
import Shallows

final class TodayExtension {
    
    static let shared = TodayExtension()
    
    let favoriteTeams: FlagsRegistry<FavoriteTeams>
    let favoriteMatches: FlagsRegistry<FavoriteMatches>
    let api: API
    let localDB: LocalDB
    let connections: Connections
    let images: Images
    
    let relevanceFilter: (Match.Full) -> Bool
    
    let reactiveRelevantMatches: Reactive<[Match.Full]>
    
    private init() {
        
        ShallowsLog.isEnabled = true
        
        self.api = API.gitHubRaw()
        self.localDB = LocalDB.inContainer(.shared)
        self.connections = Connections(api: api, localDB: localDB, activityIndicator: .none)
        let favoriteTeams = FlagsRegistry<FavoriteTeams>.inContainer(.shared)
        self.favoriteTeams = favoriteTeams
        let favoriteMatches = FlagsRegistry<FavoriteMatches>.inContainer(.shared)
        self.favoriteMatches = favoriteMatches
        self.images = Images.inContainer(.shared)
        
        let relevanceFilter: (Match.Full) -> Bool = { match in
            return match.isFavorite(isFavoriteMatch: favoriteMatches.isPresent,
                                    isFavoriteTeam: favoriteTeams.isPresent)
        }
        
        let filteredUpdate = localDB.fullMatches.didUpdate.proxy
            .map({ $0.filter(relevanceFilter) })
        self.reactiveRelevantMatches = Reactive<[Match.Full]>(valueDidUpdate: filteredUpdate.mainThread(),
                                               update: connections.fullMatches)
        self.relevanceFilter = relevanceFilter
        
    }
    
    func relevantMatches() -> [Match.Full] {
        favoriteTeams.forceRefresh()
        favoriteMatches.forceRefresh()
        return (localDB.fullMatches.getPersisted() ?? []).filter(relevanceFilter)
    }
    
}
