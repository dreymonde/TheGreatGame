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
    
    public func consume(didUpdateFavorite: Subscribe<(Team.ID, isFavorite: Bool)>, matches: ReadOnlyCache<Void, [Match.Full]>) {
        didUpdateFavorite.flatSubscribe(self, with: { $0.didUpdateFavorite($1, matches: matches) })
    }
    
    public func consume(complicationMatchUpdate: Subscribe<Match.Full>, writingTo matches: Cache<Void, Editioned<FullMatches>>) {
        complicationMatchUpdate.flatSubscribe(self, with: { $0.complicationMatchUpdate($1, matchesCache: matches) })
    }
    
    fileprivate func didUpdateFavorite(_ update: (Team.ID, isFavorite: Bool), matches: ReadOnlyCache<Void, [Match.Full]>) {
        matches.mapValues({ $0.filter({ Calendar.autoupdatingCurrent.isDateInToday($0.date) }) }).retrieve { (result) in
            if let gamesToday = result.value {
                let idsToday = Set(gamesToday.flatMap({ $0.teams.map({ $0.id }) }))
                if idsToday.contains(update.0) {
                    printWithContext("Updated team is playing today, reloading complication")
                    self.reloadComplications()
                }
            }
        }
    }
    
    fileprivate func complicationMatchUpdate(_ match: Match.Full, matchesCache: Cache<Void, Editioned<FullMatches>>) {
        matchesCache.defaulting(to: Editioned(edition: -1, content: FullMatches(matches: []))).update({ (editioned) in
            if let indexOfReceived = editioned.content.matches.index(where: { $0.id == match.id }) {
                editioned.content.matches[indexOfReceived] = match
            }
        }, completion: { result in
            if result.isSuccess {
                printWithContext("Received match update, reloading complication")
                self.reloadComplications()
            }
        })
    }
    
}
