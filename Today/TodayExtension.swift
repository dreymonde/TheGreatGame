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
    let apiCache: APICache
    let images: Images
    
    init() {
        
        ShallowsLog.isEnabled = true
        
        self.api = API.gitHub()
        self.apiCache = APICache.inSharedCachesDirectory()
        self.favoriteTeams = FavoritesRegistry.inSharedDocumentsDirectory(subpath: FavoriteTeamsSubPath)
        self.favoriteMatches = FavoritesRegistry.inSharedDocumentsDirectory(subpath: FavoriteMatchesSubPath)
        self.images = Images.inSharedCachesDirectory()
        
        self._resource = Resource<FullMatches>(local: apiCache.matches.allFull,
                                              remote: api.matches.allFull,
                                              networkActivity: .none)
            .map({ $0.matches })
    }
    
    let _resource: Resource<[Match.Full]>
    
    lazy var resource: Resource<[Match.Full]> = {
        return self._resource.map({ $0.filter(self.relevanceFilter()) })
    }()
    
    func relevanceFilter() -> (Match.Full) -> Bool {
        return { match in
            return match.isFavorite(isFavoriteMatch: self.favoriteMatches.isFavorite(id:),
                                    isFavoriteTeam: self.favoriteTeams.isFavorite(id:))
        }
    }
    
}
