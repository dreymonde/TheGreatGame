//
//  ComplicationTemplate.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

fileprivate struct TeamsNames {
    let homeLong: String
    let homeShort: String
    let awayLong: String
    let awayShort: String
}

fileprivate func names(_ homeLong: String, _ homeShort: String,
                            _ awayLong: String, _ awayShort: String) -> TeamsNames {
    return TeamsNames(homeLong: homeLong, homeShort: homeShort, awayLong: awayLong, awayShort: awayShort)
}

public final class ComplicationTemplate {
    
    public init() { }
    
    public lazy var placeholderMatch: Match.Full = self.makePlaceholderMatch(for: Locale.current)
    
    private func makePlaceholderMatch(for locale: Locale) -> Match.Full {
        if let regionNames = locale.regionCode.flatMap(teamsNames(forRegionCode:)) {
            return makePlaceholderMatch(with: regionNames)
        }
        return makeDefaultPlaceholderMatch()
    }
    
    private lazy var badges: Team.Badges = {
        let badge = URL(string: "https://goo.gl")!
        return Team.Badges(large: badge, flag: badge)
    }()
    
    private func teamsNames(forRegionCode regionCode: String) -> TeamsNames? {
        switch regionCode {
        case "RU", "UA", "BY":
            return names("Russia", "RUS", "Germany", "GER")
        case "DE":
            return names("Germany", "GER", "Sweden", "SWE")
        case "NL":
            return names("Netherlands", "NED", "Belgium", "BEL")
        case "BE":
            return names("Belgium", "BEL", "Netherlands", "NED")
        case "NO":
            return names("Norway", "NOR", "Netherlands", "NED")
        case "DK":
            return names("Denmark", "DEN", "Norway", "NOR")
        default:
            return nil
        }
    }
    
    private func makeDefaultPlaceholderMatch() -> Match.Full {
        let home = Match.Team(id: Team.ID.init(rawValue: -1)!, name: "Germany", shortName: "GER", badges: badges)
        let away = Match.Team(id: Team.ID.init(rawValue: -1)!, name: "Sweden", shortName: "SWE", badges: badges)
        return makeMatch(teams: (home, away), score: (1, 1))
    }
    
    private func makePlaceholderMatch(with names: TeamsNames) -> Match.Full {
        let home = Match.Team(id: Team.ID.init(rawValue: -1)!, name: names.homeLong, shortName: names.homeShort, badges: badges)
        let away = Match.Team(id: Team.ID.init(rawValue: -1)!, name: names.awayLong, shortName: names.awayShort, badges: badges)
        return makeMatch(teams: (home, away), score: (2, 0))
    }
    
    private func makeMatch(teams: (Match.Team, Match.Team), score: (Int, Int)?) -> Match.Full {
        let scorescore = score.map({ Match.Score.init(home: $0.0, away: $0.1) })
        return Match.Full(id: Match.ID.init(rawValue: -1)!, home: teams.0, away: teams.1, date: Date(), endDate: Date().addingTimeInterval(60 * 120), location: "Netherlands", stageTitle: "Group Stage", score: scorescore, penalties: nil, events: [])
    }
    
}
