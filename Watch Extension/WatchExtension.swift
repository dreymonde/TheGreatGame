//
//  WatchExtension.swift
//  TheGreatGame
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Alba
import TheGreatKit
import Shallows
import Avenues

final class WatchExtension {
    
    static let main = WatchExtension()
    
    let phone: Phone
    let images: Images
    let api: API
    let apiCache: APICache
    let favorites: FavoriteTeams
    let complicationReloader: ComplicationReloader
    
    init() {
        Alba.InformBureau.isEnabled = true
        Alba.InformBureau.Logger.enable()
        ShallowsLog.isEnabled = true
        self.phone = Phone()
        self.images = Images.inLocalCachesDirectory(subpath: "dev-3-images")
        self.api = API.gitHub(urlSession: URLSession.init(configuration: .default))
//        self.api = API.macBookSteve()
        self.apiCache = APICache.inLocalCachesDirectory()
        self.favorites = FavoriteTeams.inLocalDocumentsDirectory()
        self.complicationReloader = ComplicationReloader()
        declare()
    }
    
    func declare() {
        phone.didReceiveUpdatedFavorites.subscribe(self.favorites, with: FavoriteTeams.replace(with:))
        complicationReloader.consume(didUpdateFavorite: self.favorites.didUpdateFavorite.proxy,
                                     matches: apiCache.matches.allFull.backed(by: api.matches.allFull).asReadOnlyCache().mapValues({ $0.content.matches }))
        complicationReloader.consume(complicationMatchUpdate: self.phone.didReceiveComplicationMatchUpdate,
                                     writingTo: apiCache.matches.allFull)
    }
    
    func chooseMatchToShow(_ lhs: Match.Full, _ rhs: Match.Full) -> Match.Full {
        switch (lhs.isFavorite(using: favorites.isFavorite(teamWith:)),
                rhs.isFavorite(using: favorites.isFavorite(teamWith:))) {
        case (true, true), (false, false):
            return Match.endsLater(lhs, rhs)
        case (true, false):
            return lhs
        case (false, true):
            return rhs
        }
    }
    
}

extension Phone {
    
    var didReceiveComplicationMatchUpdate: Subscribe<Match.Full> {
        return didReceivePackage.proxy
            .filter({ $0.kind == .complication_match_update })
            .flatMap({ try? Match.Full.unpacked(from: $0) })
    }
    
    var didReceiveUpdatedFavorites: Subscribe<Set<Team.ID>> {
        return didReceivePackage.proxy
            .filter({ $0.kind == .favorites })
            .flatMap({ try? FavoritesPackage.unpacked(from: $0) })
            .map({ $0.favs })
    }
    
}
