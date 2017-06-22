//
//  EventViewModel.swift
//  TheGreatGame
//
//  Created by Олег on 15.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import TheGreatKit

struct EventViewModel {
    
    let minute: String
    let title: String
    let text: String
    
}

extension Match.Event {
    
    func viewModel(names: (home: String, away: String)) -> EventViewModel {
        let minute: String = {
            if case .info = kind {
                return ""
            }
            return "\(self.minute)"
        }()
        let title: String = {
            switch kind {
            case .start:
                return "Start of the game"
            case .goalHome:
                return "Goal for \(names.home)!"
            case .goalAway:
                return "Goal for \(names.away)!"
            case .end:
                return "The game has ended"
            case .info:
                return ""
            }
        }()
        return EventViewModel(minute: minute, title: title, text: text)
    }
    
}

extension Match.Event {
    
    func viewModel<Match : MatchProtocol>(in match: Match) -> EventViewModel {
        return self.viewModel(names: (home: match.home.name, away: match.away.name))
    }
    
}
