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
//        let matchesToday = logic.api.matches.all
//            .mapValues({ $0.content.matches })
////            .mapValues({ $0.filter({ Calendar.current.isDateInToday($0.date) }) })
        let matchesToday = matches.map({ $0.filter({ Calendar.autoupdatingCurrent.isDateInToday($0.date) }) })
        return MatchesInterfaceController.Context(resource: matches,
                                                  makeAvenue: logic.imageCache.makeDoubleCachedAvenue(forImageSize:))
    }
    
    static let matchesList = "MatchesInterfaceController"
    
}
