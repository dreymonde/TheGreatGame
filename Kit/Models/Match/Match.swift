//
//  Match.swift
//  TheGreatGame
//
//  Created by Олег on 05.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public protocol MatchProtocol {
    
    var id: Match.ID { get }
    var home: Match.Team { get }
    var away: Match.Team { get }
    var date: Date { get }
    var endDate: Date { get }
    var score: Match.Score? { get }
    var penalties: Match.Score? { get }
    
}

let shortTimeDateFormatter = DateFormatter() <- {
    $0.timeStyle = .short
    $0.dateStyle = .none
}

let shortDateDateFormatter = DateFormatter() <- {
    $0.setLocalizedDateFormatFromTemplate("MMMd")
}

extension String {
    fileprivate func twoLine() -> String {
        return self.components(separatedBy: ":").joined(separator: "\n")
    }
}

extension MatchProtocol {
    
    public func isFavorite(isFavoriteMatch: (Match.ID) -> Bool, isFavoriteTeam: (Team.ID) -> Bool) -> Bool {
        if isFavoriteMatch(self.id) {
            return true
        } else {
            return isFavoriteTeam(home.id) || isFavoriteTeam(away.id)
        }
    }
    
    public var teams: [Match.Team] {
        return [home, away]
    }
    
    public func isFavorite(using isFavorite: @escaping (Team.ID) -> Bool) -> Bool {
        return teams.map({ isFavorite($0.id) }).contains(true)
    }
    
    public func progress() -> Double {
        let completeInterval = endDate.timeIntervalSince(date)
        let progressInterval = Date().timeIntervalSince(date)
        return progressInterval / completeInterval
    }
    
    public func scoreOrPenaltyString() -> String {
        return penalties?.string ?? score?.string ?? "-:-"
//        if let score = score {
//            return score.demo_string
//        } else {
//            return formatter.string(from: date)
//        }
    }
    
    public func onlyMainTimeScoreString() -> String {
        return score?.string ?? "-:-"
    }
    
    public func scoreOrTimeString() -> String {
        if score != nil {
            return scoreOrPenaltyString()
        } else {
            return shortTimeDateFormatter.string(from: date)
        }
    }
    
    public func scoreOrDateString() -> String {
        if let score = score {
            return score.string
        } else {
            return "\(shortDateDateFormatter.string(from: date))\n\(shortTimeDateFormatter.string(from: date))"
        }
    }
    
}

public extension TimeInterval {
    
    public static func minutes(_ minutes: Double) -> TimeInterval {
        return 60 * minutes
    }
    
}

public enum Match {
    
    public static let duration = TimeInterval.minutes(100)
    public static let durationAndAftermath = TimeInterval.minutes(130)
    public static let aftermath = TimeInterval.minutes(20)
    
    public struct ID : RawRepresentable, Hashable, IDProtocol {
        
        public var rawID: Int
        
        public init?(rawValue: Int) {
            self.rawID = rawValue
        }
        
        public var rawValue: Int {
            return rawID
        }
        
        public var hashValue: Int {
            return rawValue
        }
        
        public func asString() -> String {
            return String(rawValue)
        }
        
    }
    
    public struct Score {
        public let home: Int
        public let away: Int
        
        public init(home: Int, away: Int) {
            self.home = home
            self.away = away
        }
        
        @available(*, deprecated)
        public var demo_string: String {
            return "\(home):\(away)"
        }
        
        public var string: String {
            return "\(home):\(away)"
        }
        
    }
    
    public struct Event {
        
        public enum Kind : String {
            case start, goal_home, goal_away, end, info, halftime_start, halftime_end
            case end_and_extra, extra_start, penalties
            case pen_goal_home, pen_goal_away, pen_miss_home, pen_miss_away
        }
        
        public let kind: Kind
        public let text: String
        public let realMinute: Int
        public let matchMinute: Int
        
        public init(kind: Kind, text: String, realMinute: Int, matchMinute: Int) {
            if let extra = Event.analyze(text, kind: kind) {
                self.kind = extra.0
                self.text = extra.1
            } else {
                self.kind = kind
                self.text = text
            }
            self.realMinute = realMinute
            self.matchMinute = matchMinute
        }
        
        internal enum Additional {
            static let endAndExtra = "FE "
            static let extraTimeStart = "ET "
            static let penalties = "PS "
            static let penGoalHome = "PH "
            static let penGoalAway = "PA "
            static let penHomeMiss = "MH "
            static let penAwayMiss = "MA "
        }
        
        internal static func analyze(_ text: String, kind: Kind) -> (Kind, String)? {
            if text.hasPrefix(Additional.endAndExtra), kind == .halftime_start {
                let cut = cutAdditional(from: text)
                return (.end_and_extra, cut)
            }
            if text.hasPrefix(Additional.extraTimeStart), kind == .halftime_end {
                let cut = cutAdditional(from: text)
                return (.extra_start, cut)
            }
            if text.hasPrefix(Additional.penalties), kind == .halftime_start {
                let cut = cutAdditional(from: text)
                return (.penalties, cut)
            }
            if text.hasPrefix(Additional.penGoalHome), kind == .info {
                let cut = cutAdditional(from: text)
                return (.pen_goal_home, cut)
            }
            if text.hasPrefix(Additional.penGoalAway), kind == .info {
                let cut = cutAdditional(from: text)
                return (.pen_goal_away, cut)
            }
            if text.hasPrefix(Additional.penHomeMiss), kind == .info {
                let cut = cutAdditional(from: text)
                return (.pen_miss_home, cut)
            }
            if text.hasPrefix(Additional.penAwayMiss), kind == .info {
                let cut = cutAdditional(from: text)
                return (.pen_miss_away, cut)
            }
            return nil
        }
        
        internal static func cutAdditional(from text: String) -> String {
            return String(text[text.index(text.startIndex, offsetBy: 3)...])
        }
        
    }
    
    public struct Team {
        public let id: TheGreatKit.Team.ID
        public let name: String
        public let shortName: String
        public let shortestName: String
        public let badges: TheGreatKit.Team.Badges
    }
    
    public struct Compact : MatchProtocol {
        
        public let id: Match.ID
        public let home: Team
        public let away: Team
        public let date: Date
        public let endDate: Date
        public let location: String
        public var score: Score?
        public var penalties: Match.Score?
        
    }
    
    public struct Full : MatchProtocol {
        
        public let id: Match.ID
        public let home: Team
        public let away: Team
        public let date: Date
        public let endDate: Date
        public let location: String
        public let stageTitle: String
        public var score: Score?
        public var penalties: Match.Score?
        public var events: [Event]
        
        public static func reevaluateScore(from events: [Event]) -> Score? {
            guard events.contains(where: { $0.kind == .start }) else {
                return nil
            }
            let goalsHome = events.filter({ $0.kind == .goal_home }).count
            let goalsAway = events.filter({ $0.kind == .goal_away }).count
            return Score(home: goalsHome, away: goalsAway)
        }
        
        public static func reevaluatePenalties(from events: [Event]) -> Score? {
            guard events.contains(eventOfKind: .penalties) else {
                return nil
            }
            let pensHome = events.filter({ $0.kind == .pen_goal_home }).count
            let pensAway = events.filter({ $0.kind == .pen_goal_away }).count
            return Score(home: pensHome, away: pensAway)
        }
        
        public func withUnpredictableScore() -> Full {
            var copy = self
            if copy.score != nil {
                copy.score = Score(home: -1, away: -1)
            }
            return copy
        }
        
        public func date(afterRealMinutesFromStart realMinutes: Int) -> Date {
            return self.date.addingTimeInterval(TimeInterval(60 * realMinutes))
        }
        
        public func snapshot(beforeRealMinute realMinute: Int) -> Full {
            let eventsBeforeMinute = events.filter({ $0.realMinute <= realMinute })
            return Full(id: self.id,
                        home: self.home,
                        away: self.away,
                        date: date,
                        endDate: endDate,
                        location: location,
                        stageTitle: stageTitle,
                        score: Full.reevaluateScore(from: eventsBeforeMinute),
                        penalties: Full.reevaluatePenalties(from: eventsBeforeMinute),
                        events: eventsBeforeMinute)
        }
        
        public func allSnapshots() -> [(match: Full, minute: Int)] {
            return events.map({ (event) in
                return (self.snapshot(beforeRealMinute: event.realMinute), minute: event.realMinute)
            })
        }
        
        public func notStartedSnapshot() -> Full {
            return snapshot(beforeRealMinute: -1)
        }
        
        public var isFullTime: Bool {
            return isEnded || events.contains(eventOfKind: .end_and_extra)
        }
        
        public var isOn: Bool {
            return isStarted && !isEnded
        }
        
        public var isEnded: Bool {
            return events.contains(eventOfKind: .end)
        }
        
        public var isStarted: Bool {
            return events.contains(eventOfKind: .start)
        }
        
        public var isInHalfTime: Bool {
            return (isFirstHalfEnded && !isMainHalfTimeEnded) || (isExtraTimeAppointed && !isExtraTime && !isEnded && !isPenaltiesAppointed)
        }
        
        public var isSecondHalf: Bool {
            return isMainHalfTimeEnded && !isFullTime
        }
        
        public var isMainHalfTimeEnded: Bool {
            return events.contains(eventOfKind: .halftime_end)
        }
        
        public var isFirstHalf: Bool {
            return !isFirstHalfEnded
        }
        
        public var isFirstHalfEnded: Bool {
            return events.contains(eventOfKind: .halftime_start)
        }
        
        public var isExtraTimeAppointed: Bool {
            return events.contains(eventOfKind: .end_and_extra)
        }
        
        public var isExtraTime: Bool {
            return events.contains(eventOfKind: .extra_start) && !isExtraTimeEnded
        }
        
        public var isExtraTimeEnded: Bool {
            return isPenaltiesAppointed || isEnded
        }
        
        public var isPenaltiesAppointed: Bool {
            return events.contains(eventOfKind: .penalties)
        }
        
        public var isPenalties: Bool {
            return isPenaltiesAppointed && !isEnded
        }
        
        public func minuteOrStateString() -> String {
            if !isStarted {
                return " "
            }
            if isEnded {
                return "FT"
            }
            if isInHalfTime {
                return "HT"
            }
            if let lastEvent = events.last {
                let dateOfLastEvent = self.date(afterRealMinutesFromStart: lastEvent.realMinute)
                let intervalAfter = Int(Date().timeIntervalSince(dateOfLastEvent) / 60)
                var string = "\(lastEvent.matchMinute + intervalAfter)'"
                if isExtraTimeAppointed {
                    string.append(" ET")
                }
                return string
            } else {
                return " "
            }
        }
        
    }
    
}

extension Sequence where Iterator.Element == Match.Event {
    
    func contains(eventOfKind kind: Match.Event.Kind) -> Bool {
        return contains(where: { $0.kind == kind })
    }
    
}

extension Match.Team : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case id, name, badges, short_name, shortest_name, summary
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.id = try mapper.map(from: .id)
        self.name = try mapper.map(from: .name)
        self.badges = try mapper.map(from: .badges)
        self.shortName = try mapper.map(from: .short_name)
        self.shortestName = try mapper.map(from: .shortest_name)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.id, to: .id)
        try mapper.map(self.name, to: .name)
        try mapper.map(self.badges, to: .badges)
        try mapper.map(self.shortName, to: .short_name)
        try mapper.map(self.shortestName, to: .shortest_name)
    }
    
}

extension Match.Score : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case home, away
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.home = try mapper.map(from: .home)
        self.away = try mapper.map(from: .away)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.home, to: .home)
        try mapper.map(self.away, to: .away)
    }
    
}

extension Match.Event : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case type, text, real_minute, match_minute
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        let kind = try mapper.map(from: .type) as Kind
        let text = try mapper.map(from: .text) as String
        let realMinute = try mapper.map(from: .real_minute) as Int
        let matchMinute = try mapper.map(from: .match_minute) as Int
        self.init(kind: kind, text: text, realMinute: realMinute, matchMinute: matchMinute)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.kind, to: .type)
        try mapper.map(self.text, to: .text)
        try mapper.map(self.realMinute, to: .real_minute)
        try mapper.map(self.matchMinute, to: .match_minute)
    }
    
}

extension Match.Compact : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case id, home, away, date, endDate, location, score, penalties
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.id = try mapper.map(from: .id)
        self.home = try mapper.map(from: .home)
        self.away = try mapper.map(from: .away)
        self.date = try mapper.map(from: .date)
        self.endDate = try mapper.map(from: .endDate)
        self.location = try mapper.map(from: .location)
        self.score = try? mapper.map(from: .score)
        self.penalties = try? mapper.map(from: .penalties)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.id, to: .id)
        try mapper.map(self.home, to: .home)
        try mapper.map(self.away, to: .away)
        try mapper.map(self.date, to: .date)
        try mapper.map(self.endDate, to: .endDate)
        try mapper.map(self.location, to: .location)
        if let score = self.score {
            try mapper.map(score, to: .score)
        }
        if let pens = self.penalties {
            try mapper.map(pens, to: .penalties)
        }
    }
    
}

extension Match.Full : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case id, home, away, date, endDate, location, score, events, stage_title, penalties
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.id = try mapper.map(from: .id)
        self.home = try mapper.map(from: .home)
        self.away = try mapper.map(from: .away)
        self.date = try mapper.map(from: .date)
        self.endDate = try mapper.map(from: .endDate)
        self.location = try mapper.map(from: .location)
        self.stageTitle = try mapper.map(from: .stage_title)
        self.events = try mapper.map(from: .events)
        self.score = try? mapper.map(from: .score)
        self.penalties = try? mapper.map(from: .penalties)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.id, to: .id)
        try mapper.map(self.home, to: .home)
        try mapper.map(self.away, to: .away)
        try mapper.map(self.date, to: .date)
        try mapper.map(self.endDate, to: .endDate)
        try mapper.map(self.location, to: .location)
        try mapper.map(self.stageTitle, to: .stage_title)
        try mapper.map(self.events, to: .events)
        if let score = self.score {
            try mapper.map(score, to: .score)
        }
        if let pens = self.penalties {
            try mapper.map(pens, to: .penalties)
        }
    }
    
}

public struct Matches {
    
    public let matches: [Match.Compact]
    
}

extension Matches : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case matches
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.matches = try mapper.map(from: .matches)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.matches, to: .matches)
    }
    
}

public struct FullMatches {
    
    public var matches: [Match.Full]
    
    public init(matches: [Match.Full]) {
        self.matches = matches
    }
    
}

extension FullMatches : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case matches
    }
    
    public init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.matches = try mapper.map(from: .matches)
    }
    
    public func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.matches, to: .matches)
    }
    
}

public protocol HasStartDate {
    var date: Date { get }
}

extension Match.Compact : HasStartDate { }
extension Match.Full : HasStartDate { }

extension Sequence where Iterator.Element : HasStartDate {
    
    public func mostRelevant() -> Iterator.Element? {
        return sorted(by: { first, second in
            let now = Date()
            return abs(now.timeIntervalSince(first.date)) < abs(now.timeIntervalSince(second.date))
        }).first
    }
    
    public func firstToStart(after givenDate: Date) -> Iterator.Element? {
        return filter({ $0.date > givenDate }).sorted(by: { $0.date < $1.date }).first
    }
    
}
