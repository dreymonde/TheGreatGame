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
    let matches: Resource<[Match.Full]>
    
    init(watchExtension: WatchExtension) {
        self.logic = watchExtension
        self.matches = Resource<FullMatches>(local: logic.apiCache.matches.allFull,
                                             remote: logic.api.matches.allFull,
                                             networkActivity: .none)
            .map({ $0.matches })
    }
    
    func preloadFullMatches() {
        matches.load(completion: { _ in printWithContext("Loaded full matches") })
    }
    
    func makeContext(for contr: MatchesInterfaceController.Type) -> MatchesInterfaceController.Context {
        let relevantMatches = matches.map { (all) -> [Match.Full] in
            let allUpcoming = all.filter({ !$0.isStarted || Calendar.autoupdatingCurrent.isDateInToday($0.date) })
            if let firstUpcoming = allUpcoming.min(by: { $0.date < $1.date }) {
                return all.filter({ Calendar.autoupdatingCurrent.isDate($0.date, inSameDayAs: firstUpcoming.date) })
            }
            return []
        }
        return MatchesInterfaceController.Context(resource: relevantMatches,
                                                  makeAvenue: logic.images.makeDoubleCachedAvenue(forImageSize:))
    }
    
    static let matchesList = "MatchesInterfaceController"
    
}
