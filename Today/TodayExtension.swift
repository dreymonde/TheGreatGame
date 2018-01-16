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
    
    let favoriteTeams: FavoritesRegistry<RD.Teams>
    let favoriteMatches: FavoritesRegistry<RD.Matches>
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
        self.favoriteTeams = FavoritesRegistry.inLocation(.sharedDocuments)
        self.favoriteMatches = FavoritesRegistry.inLocation(.sharedDocuments)
        self.images = Images.inLocation(.sharedCaches)
        
        self.reactive = Reactive<[Match.Full]>(valueDidUpdate: localDB.fullMatches.didUpdate.proxy.mainThread(),
                                               update: connections.fullMatches)
        
    }
    
    func relevanceFilter() -> (Match.Full) -> Bool {
        return { match in
            return match.isFavorite(isFavoriteMatch: self.favoriteMatches.isFavorite(id:),
                                    isFavoriteTeam: self.favoriteTeams.isFavorite(id:))
        }
    }
    
}
