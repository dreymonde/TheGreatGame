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
import Shallows

final class TodayExtension {
    
    let favoriteTeams: FavoritesRegistry<Team.ID>
    let favoriteMatches: FavoritesRegistry<Match.ID>
    let api: API
    let localDB: LocalDB
    let connections: Connections
    let images: Images
    
    let reactive: Reactive<[Match.Full]>
    
    init() {
        
        ShallowsLog.isEnabled = true
        
        self.api = API.gitHub()
        self.localDB = LocalDB.inSharedDocumentsFolder()
        self.connections = Connections(api: api, localDB: localDB, activityIndicator: .none)
        self.favoriteTeams = FavoritesRegistry.inSharedDocumentsDirectory(subpath: FavoriteTeamsSubPath)
        self.favoriteMatches = FavoritesRegistry.inSharedDocumentsDirectory(subpath: FavoriteMatchesSubPath)
        self.images = Images.inSharedCachesDirectory()
        
        self.reactive = Reactive<[Match.Full]>(proxy: localDB.fullMatches.didUpdate.proxy.mainThread(),
                                               update: connections.fullMatches)
        
    }
    
    func relevanceFilter() -> (Match.Full) -> Bool {
        return { match in
            return match.isFavorite(isFavoriteMatch: self.favoriteMatches.isFavorite(id:),
                                    isFavoriteTeam: self.favoriteTeams.isFavorite(id:))
        }
    }
    
}
