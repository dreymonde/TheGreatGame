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
    
    let favoriteTeams: FavoritesRegistry<RD.Teams>
    let favoriteMatches: FavoritesRegistry<RD.Matches>
    let api: API
    let localDB: LocalDB
    let connections: Connections
    let images: Images
    
    let relevanceFilter: (Match.Full) -> Bool
    
    let reactiveRelevantMatches: Reactive<[Match.Full]>
    
    init() {
        
        ShallowsLog.isEnabled = true
        
        self.api = API.gitHub()
        self.localDB = LocalDB.inSharedCachesFolder()
        self.connections = Connections(api: api, localDB: localDB, activityIndicator: .none)
        let favoriteTeams = FavoritesRegistry<RD.Teams>.inLocation(.sharedDocuments)
        self.favoriteTeams = favoriteTeams
        let favoriteMatches = FavoritesRegistry<RD.Matches>.inLocation(.sharedDocuments)
        self.favoriteMatches = favoriteMatches
        self.images = Images.inLocation(.sharedCaches)
        
        let relevanceFilter: (Match.Full) -> Bool = { match in
            return match.isFavorite(isFavoriteMatch: favoriteMatches.isFavorite(id:),
                                    isFavoriteTeam: favoriteTeams.isFavorite(id:))
        }
        
        let filteredUpdate = localDB.fullMatches.didUpdate.proxy
            .map({ $0.filter(relevanceFilter) })
        self.reactiveRelevantMatches = Reactive<[Match.Full]>(valueDidUpdate: filteredUpdate.mainThread(),
                                               update: connections.fullMatches)
        self.relevanceFilter = relevanceFilter
        
    }
    
    func relevantMatches() -> [Match.Full] {
        return (localDB.fullMatches.get() ?? []).filter(relevanceFilter)
    }
    
}
