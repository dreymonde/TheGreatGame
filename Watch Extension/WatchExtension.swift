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
    let matchesAPI: MatchesAPI
    let matchesDB: LocalModel<[Match.Full]>
    let favoriteTeams: FlagsRegistry<FavoriteTeams>
    let favoriteMatches: FlagsRegistry<FavoriteMatches>
    let complicationReloader: ComplicationReloader
    
    init() {
        #if DEBUG
        Alba.InformBureau.isEnabled = true
        Alba.InformBureau.Logger.enable()
        #endif
        ShallowsLog.isEnabled = true
        self.phone = Phone()
        self.images = Images.inContainer(.appFolder)
        self.matchesAPI = MatchesAPI.gitHubRaw()
        self.matchesDB = LocalModel<[Match.Full]>.inStorage(
            Disk.init(directory: AppFolder.Library.Application_Support.db),
            filename: "all-matches"
        )
        self.favoriteTeams = FlagsRegistry.inContainer(.appFolder)
        self.favoriteMatches = FlagsRegistry.inContainer(.appFolder)
        self.complicationReloader = ComplicationReloader()
        subscribe()
    }
    
    func subscribe() {
        phone.didReceiveUpdatedFavoriteTeams.subscribe(self.favoriteTeams, with: FlagsRegistry.replace)
        phone.didReceiveUpdatedFavoriteMatches.subscribe(self.favoriteMatches, with: FlagsRegistry.replace)
        complicationReloader.consume(favoriteTeamsDidUpdate: self.favoriteTeams.didUpdatePresence, favoriteMatchesDidUpdate: self.favoriteMatches.didUpdatePresence)
        complicationReloader.consume(complicationMatchUpdate: self.phone.didReceiveComplicationMatchUpdate,
                                     writingTo: matchesDB.io)
    }
    
    func isFavoriteMatch(_ match: Match.Full) -> Bool {
        return match.isFavorite(isFavoriteMatch: self.favoriteMatches.isPresent,
                                isFavoriteTeam: self.favoriteTeams.isPresent)
    }
    
    func chooseMatchToShow(_ lhs: Match.Full, _ rhs: Match.Full) -> Match.Full {
        switch (isFavoriteMatch(lhs),
                isFavoriteMatch(rhs)) {
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
    
    var didReceiveUpdatedFavoriteTeams: Subscribe<FavoriteTeams.Set> {
        return didReceivePackage.proxy
            .adapting(with: IDPackage.packageToIDsSet)
    }
    
    var didReceiveUpdatedFavoriteMatches: Subscribe<FavoriteMatches.Set> {
        return didReceivePackage.proxy
            .adapting(with: IDPackage.packageToIDsSet)
    }

}
