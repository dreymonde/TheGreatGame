//
//  ComplicationReloader.swift
//  TheGreatGame
//
//  Created by Олег on 30.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import ClockKit
import Alba
import Shallows

public final class ComplicationReloader {
    
    let server = CLKComplicationServer.sharedInstance()
    
    public init() { }
    
    public func reloadComplications() {
        DispatchQueue.main.async {
            if let complications = self.server.activeComplications {
                printWithContext("Reloading complications")
                for complication in complications {
                    self.server.reloadTimeline(for: complication)
                }
            }
        }
    }
    
}

extension ComplicationReloader {
    
    public func consume(favoriteTeamsDidUpdate: Subscribe<Flags<FavoriteTeams>.Change>,
                        favoriteMatchesDidUpdate: Subscribe<Flags<FavoriteMatches>.Change>) {
        favoriteTeamsDidUpdate.flatSubscribe(self, with: { $0.didUpdateFavorite($1) })
        favoriteMatchesDidUpdate.flatSubscribe(self, with: { $0.didUpdateFavorite($1) })
    }
    
    public func consume(complicationMatchUpdate: Subscribe<Match.Full>, writingTo matches: Storage<Void, [Match.Full]>) {
        complicationMatchUpdate.flatSubscribe(self, with: { $0.complicationMatchUpdate($1, matchesCache: matches) })
    }
    
    fileprivate func didUpdateFavorite(_ update: Flags<FavoriteTeams>.Change) {
        printWithContext("Reloading complication")
        self.reloadComplications()
    }
    
    fileprivate func didUpdateFavorite(_ update: Flags<FavoriteMatches>.Change) {
        printWithContext("Reloaing complication")
        self.reloadComplications()
    }
    
    fileprivate func complicationMatchUpdate(_ match: Match.Full, matchesCache: Storage<Void, [Match.Full]>) {
        matchesCache.defaulting(to: []).update({ (matches) in
            if let indexOfReceived = matches.index(where: { $0.id == match.id }) {
                matches[indexOfReceived] = match
            }
        }, completion: { result in
            if result.isSuccess {
                printWithContext("Received match update, reloading complication")
                self.reloadComplications()
            }
        })
    }
    
}
