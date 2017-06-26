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
    
}

let formatter = DateFormatter() <- {
    $0.dateStyle = .none
    $0.timeStyle = .short
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
    
    public func scoreString() -> String {
        return score?.demo_string ?? "-:-"
//        if let score = score {
//            return score.demo_string
//        } else {
//            return formatter.string(from: date)
//        }
    }
    
}

public enum Match {
    
    public static let duration = TimeInterval(60 * 100)
    public static let durationAndAftermath = TimeInterval(60 * 130)
    public static let aftermath = TimeInterval(60 * 30)
    
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
        
        public var demo_string: String {
            return "\(home):\(away)"
        }
        
    }
    
    public struct Event {
        
        public enum Kind : String {
            case start, goalHome, goalAway, end, info
        }
        
        public let kind: Kind
        public let text: String
        public let minute: Int
        
        public init(kind: Kind, text: String, minute: Int) {
            self.kind = kind
            self.text = text
            self.minute = minute
        }
        
    }
    
    public struct Team {
        public let id: TheGreatKit.Team.ID
        public let name: String
        public let shortName: String
        public let badges: TheGreatKit.Team.Badges
    }
    
    public struct Compact : MatchProtocol {
        
        public let id: Match.ID
        public let home: Team
        public let away: Team
        public let date: Date
        public let endDate: Date
        public let location: String
        public let score: Score?
        
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
        public var events: [Event]
        
        public static func reevaluateScore(from events: [Event]) -> Score? {
            guard events.contains(where: { $0.kind == .start }) else {
                return nil
            }
            let goalsHome = events.filter({ $0.kind == .goalHome }).count
            let goalsAway = events.filter({ $0.kind == .goalAway }).count
            return Score(home: goalsHome, away: goalsAway)
        }
        
        public func withUnpredictableScore() -> Full {
            var copy = self
            if copy.score != nil {
                copy.score = Score(home: -1, away: -1)
            }
            return copy
        }
        
        public func date(afterMinutesFromStart minutes: Int) -> Date {
            return self.date.addingTimeInterval(TimeInterval(60 * minutes))
        }
        
        public func snapshot(beforeMinute minute: Int) -> Full {
            let eventsBeforeMinute = events.filter({ $0.minute <= minute })
            return Full(id: self.id,
                        home: self.home,
                        away: self.away,
                        date: date,
                        endDate: endDate,
                        location: location,
                        stageTitle: stageTitle,
                        score: Full.reevaluateScore(from: eventsBeforeMinute),
                        events: eventsBeforeMinute)
        }
        
        public func allSnapshots() -> [(match: Full, minute: Int)] {
            return events.map({ (event) in
                return (self.snapshot(beforeMinute: event.minute), minute: event.minute)
            })
        }
        
        public func notStartedSnapshot() -> Full {
            return snapshot(beforeMinute: -1)
        }
        
        public var isEnded: Bool {
            return events.contains(where: { $0.kind == .end })
        }
        
        public var isStarted: Bool {
            return events.contains(where: { $0.kind == .start })
        }
        
    }
    
}

extension Match.Team : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case id, name, badges, short_name, summary
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.id = try mapper.map(from: .id)
        self.name = try mapper.map(from: .name)
        self.badges = try mapper.map(from: .badges)
        self.shortName = try mapper.map(from: .short_name)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.id, to: .id)
        try mapper.map(self.name, to: .name)
        try mapper.map(self.badges, to: .badges)
        try mapper.map(self.shortName, to: .short_name)
    }
    
}

extension Match.Score : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case home, away
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.home = try mapper.map(from: .home)
        self.away = try mapper.map(from: .away)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.home, to: .home)
        try mapper.map(self.away, to: .away)
    }
    
}

extension Match.Event : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case type, text, minute
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.kind = try mapper.map(from: .type)
        self.text = try mapper.map(from: .text)
        self.minute = try mapper.map(from: .minute)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.kind, to: .type)
        try mapper.map(self.text, to: .text)
        try mapper.map(self.minute, to: .minute)
    }
    
}

extension Match.Compact : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case id, home, away, date, endDate, location, score
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.id = try mapper.map(from: .id)
        self.home = try mapper.map(from: .home)
        self.away = try mapper.map(from: .away)
        self.date = try mapper.map(from: .date)
        self.endDate = try mapper.map(from: .endDate)
        self.location = try mapper.map(from: .location)
        self.score = try? mapper.map(from: .score)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.id, to: .id)
        try mapper.map(self.home, to: .home)
        try mapper.map(self.away, to: .away)
        try mapper.map(self.date, to: .date)
        try mapper.map(self.endDate, to: .endDate)
        try mapper.map(self.location, to: .location)
        if let score = self.score {
            try mapper.map(score, to: .score)
        }
    }
    
}

extension Match.Full : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case id, home, away, date, endDate, location, score, events, stage_title
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.id = try mapper.map(from: .id)
        self.home = try mapper.map(from: .home)
        self.away = try mapper.map(from: .away)
        self.date = try mapper.map(from: .date)
        self.endDate = try mapper.map(from: .endDate)
        self.location = try mapper.map(from: .location)
        self.stageTitle = try mapper.map(from: .stage_title)
        self.events = try mapper.map(from: .events)
        self.score = try? mapper.map(from: .score)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
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
    }
    
}

public struct Matches {
    
    public let matches: [Match.Compact]
    
}

extension Matches : Mappable {
    
    public enum MappingKeys : String, IndexPathElement {
        case matches
    }
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.matches = try mapper.map(from: .matches)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
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
    
    public init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.matches = try mapper.map(from: .matches)
    }
    
    public func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
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
