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
    let homeShortest: String
    let awayLong: String
    let awayShort: String
    let awayShortest: String
}

fileprivate func names(_ homeLong: String, _ homeShort: String, _ homeShortest: String,
                       _ awayLong: String, _ awayShort: String, _ awayShortest: String) -> TeamsNames {
    return TeamsNames(homeLong: homeLong, homeShort: homeShort, homeShortest: homeShortest, awayLong: awayLong, awayShort: awayShort, awayShortest: awayShortest)
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
            return names("Russia", "RUS", "RU", "Germany", "GER", "DE")
        case "DE":
            return names("Germany", "GER", "DE", "Sweden", "SWE", "SE")
        case "NL":
            return names("Netherlands", "NED", "NL", "Belgium", "BEL", "BE")
        case "BE":
            return names("Belgium", "BEL", "BE", "Netherlands", "NED", "NL")
        case "NO":
            return names("Norway", "NOR", "NO", "Netherlands", "NED", "NL")
        case "DK":
            return names("Denmark", "DEN", "DK", "Norway", "NOR", "NO")
        default:
            return nil
        }
    }
    
    private func makeDefaultPlaceholderMatch() -> Match.Full {
        let home = Match.Team(id: Team.ID.init(rawValue: -1)!, name: "Germany", shortName: "GER", shortestName: "GE", badges: badges)
        let away = Match.Team(id: Team.ID.init(rawValue: -1)!, name: "Sweden", shortName: "SWE", shortestName: "SE", badges: badges)
        return makeMatch(teams: (home, away), score: (1, 1))
    }
    
    private func makePlaceholderMatch(with names: TeamsNames) -> Match.Full {
        let home = Match.Team(id: Team.ID.init(rawValue: -1)!, name: names.homeLong, shortName: names.homeShort, shortestName: names.homeShortest, badges: badges)
        let away = Match.Team(id: Team.ID.init(rawValue: -1)!, name: names.awayLong, shortName: names.awayShort, shortestName: names.awayShortest, badges: badges)
        return makeMatch(teams: (home, away), score: (2, 0))
    }
    
    private func makeMatch(teams: (Match.Team, Match.Team), score: (Int, Int)?) -> Match.Full {
        let scorescore = score.map({ Match.Score.init(home: $0.0, away: $0.1) })
        return Match.Full(id: Match.ID.init(rawValue: -1)!, home: teams.0, away: teams.1, date: Date(), endDate: Date().addingTimeInterval(60 * 120), location: "Netherlands", stageTitle: "Group Stage", score: scorescore, penalties: nil, events: [])
    }
    
}
