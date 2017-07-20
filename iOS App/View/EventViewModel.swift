//
//  EventViewModel.swift
//  TheGreatGame
//
//  Created by Олег on 15.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public struct EventViewModel {
    
    public let minute: String
    public let title: String?
    public let text: String
    
}

extension Match.Event {
    
    public func viewModel(names: (home: String, away: String)) -> EventViewModel {
        let minute: String = {
            switch kind {
            case .info, .pen_goal_home, .pen_goal_away, .pen_miss_home, .pen_miss_away:
                return ""
            default:
                return "\(self.matchMinute)"
            }
        }()
        let title: String? = {
            switch kind {
            case .start:
                return "Start of the game"
            case .goal_home:
                return "Goal for \(names.home)!"
            case .goal_away:
                return "Goal for \(names.away)!"
            case .halftime_start:
                return "End of the first half"
            case .halftime_end:
                return "Start of the second half"
            case .end:
                return "The game has ended"
            case .end_and_extra:
                return "Extra time"
            case .extra_start:
                return "Start of the extra time"
            case .penalties:
                return "Penalties"
            case .pen_goal_home:
                return "\(names.home): goal"
            case .pen_goal_away:
                return "\(names.away): goal"
            case .pen_miss_home:
                return "\(names.home): miss!"
            case .pen_miss_away:
                return "\(names.away): miss!"
            case .info:
                return nil
            }
        }()
        return EventViewModel(minute: minute, title: title, text: text)
    }
    
}

extension Match.Event {
    
    public func viewModel<Match : MatchProtocol>(in match: Match) -> EventViewModel {
        return self.viewModel(names: (home: match.home.name, away: match.away.name))
    }
    
}
