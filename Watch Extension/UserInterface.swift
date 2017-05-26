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
    
    func makeContext(for contr: MatchesInterfaceController.Type) -> MatchesInterfaceController.Context {
        let matchesToday = logic.api.matches.all
            .mapValues({ $0.content.matches })
//            .mapValues({ $0.filter({ Calendar.current.isDateInToday($0.date) }) })
        return MatchesInterfaceController.Context(provider: matchesToday,
                                                  makeAvenue: logic.imageCache.makeAvenue(forImageSize:))
    }
    
    static let matchesList = "MatchesInterfaceController"
    
}
