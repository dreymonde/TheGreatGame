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
        if let complications = server.activeComplications {
            printWithContext("Reloading complications")
            for complication in complications {
                server.reloadTimeline(for: complication)
            }
        }
    }
    
}

extension ComplicationReloader {
    
    public func consume(didUpdateFavorite: Subscribe<(Team.ID, isFavorite: Bool)>, matches: ReadOnlyCache<Void, [Match.Full]>) {
        didUpdateFavorite.flatSubscribe(self, with: { $0.didUpdateFavorite($1, matches: matches) })
    }
    
    fileprivate func didUpdateFavorite(_ update: (Team.ID, isFavorite: Bool), matches: ReadOnlyCache<Void, [Match.Full]>) {
        matches.mapValues({ $0.filter({ Calendar.autoupdatingCurrent.isDateInToday($0.date) }) }).retrieve { (result) in
            if let gamesToday = result.asOptional {
                let idsToday = Set(gamesToday.flatMap({ $0.teams.map({ $0.id }) }))
                if idsToday.contains(update.0) {
                    DispatchQueue.main.async {
                        printWithContext("Updated team is playing today, reloading complication")
                        self.reloadComplications()
                    }
                }
            }
        }
    }
    
}
