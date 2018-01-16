//
//  UserInterface.swift
//  TheGreatGame
//
//  Created by Олег on 26.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import WatchKit
import TheGreatKit

final class UserInterface {
    
    let logic: WatchExtension
    
    init(watchExtension: WatchExtension) {
        self.logic = watchExtension
    }
    
    func preloadFullMatches() {
        //matches.load(completion: { _,_ in printWithContext("Loaded full matches") })
    }
    
    private func filter(matches: [Match.Full]) -> [Match.Full] {
        let allUpcoming = matches.filter({ $0.isStarted.not || Calendar.autoupdatingCurrent.isDateInToday($0.date) })
        if let firstUpcoming = allUpcoming.min(by: { $0.date < $1.date }) {
            return matches.filter({ Calendar.autoupdatingCurrent.isDate($0.date,
                                                                        inSameDayAs: firstUpcoming.date)})
        }
        return matches.last.map({ [$0] }) ?? []
    }
    
    func makeContext(for contr: MatchesInterfaceController.Type) -> MatchesInterfaceController.Context {
        let db = logic.matchesDB
        let relevantMatches = filter(matches: db.get() ?? [])
        let apiCall = logic.matchesAPI.allFull.mapValues({ $0.content.matches })
        let reactive = Reactive(valueDidUpdate: db.didUpdate.proxy.map(filter(matches:)).mainThread(),
                                update: APIFireUpdate(retrieve: apiCall,
                                                      write: db.writeAccess,
                                                      activityIndicator: .none))
        return MatchesInterfaceController.Context(matches: relevantMatches,
                                                  reactive: reactive,
                                                  makeAvenue: logic.images.makeDoubleCachedAvenue(forImageSize:))
    }
    
    static let matchesList = "MatchesInterfaceController"
    
}
