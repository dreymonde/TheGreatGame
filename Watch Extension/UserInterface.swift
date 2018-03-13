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
        let allUpcoming = matches.filter({ $0.isNotStarted || $0.date.isToday })
        if let firstUpcoming = allUpcoming.min(by: { $0.date < $1.date }) {
            return matches.filter({ $0.date.isSameDay(as: firstUpcoming.date) })
        }
        return matches.last.map({ [$0] }) ?? []
    }
    
    func makeContext(for contr: MatchesInterfaceController.Type) -> MatchesInterfaceController.Context {
        let db = logic.matchesDB
        let relevantMatches = filter(matches: db.getInMemory() ?? [])
        let apiCall = logic.matchesAPI.allFull.mapValues({ $0.content.matches })
        let reactive = Reactive(valueDidUpdate: db.inMemoryValueDidUpdate.map(filter(matches:)).mainThread(),
                                update: APIFireUpdate(retrieve: apiCall,
                                                      write: db.set,
                                                      activityIndicator: .none))
        return MatchesInterfaceController.Context(matches: relevantMatches,
                                                  reactive: reactive,
                                                  makeAvenue: self.logic.images.makeDoubleCachedAvenue(forImageSize:))
    }
    
    static let matchesList = "MatchesInterfaceController"
    
}

fileprivate extension Date {
    
    static var cal: Calendar {
        return .autoupdatingCurrent
    }
    
    var isToday: Bool {
        return Date.cal.isDateInToday(self)
    }
    
    func isSameDay(as otherDate: Date) -> Bool {
        return Date.cal.isDate(self, inSameDayAs: otherDate)
    }
    
}
