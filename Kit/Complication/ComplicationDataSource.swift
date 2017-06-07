//
//  ComplicationDataSource.swift
//  TheGreatGame
//
//  Created by Олег on 28.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

func onlySuccess<T>(_ completion: @escaping (T) -> ()) -> (Result<T>) -> () {
    return { res in
        if let val = res.value {
            completion(val)
        }
    }
}

func asOptional<T>(_ completion: @escaping (T?) -> ()) -> (Result<T>) -> () {
    return { completion($0.value) }
}

public func endsLater(_ lhs: Match.Full, _ rhs: Match.Full) -> Match.Full {
    if lhs.endDate > rhs.endDate {
        return lhs
    }
    return rhs
}

public final class ComplicationDataSource {
    
    public struct MatchSnapshot {
        public let match: Match.Full
        public let timelineDate: Date
        
        public init(match: Match.Full, timelineDate: Date) {
            self.match = match
            self.timelineDate = timelineDate
        }
    }
    
    public let matches: ReadOnlyCache<Void, [Match.Full]>
    public let conflictResolver: (Match.Full, Match.Full) -> Match.Full
    
    public init(provider: ReadOnlyCache<Void, [Match.Full]>,
                conflictResolver: @escaping (Match.Full, Match.Full) -> Match.Full) {
        let finalProvider = provider.mapValues({ $0.removingStartingAtTheSameDate(with: conflictResolver) })
        self.matches = finalProvider
        self.conflictResolver = conflictResolver
    }
    
    public func timelineStartDate(completion: @escaping (Date?) -> ()) {
        matches.retrieve { (result) in
            completion(result.value?.timelineStartDate())
        }
    }
    
    public func timelineEndDate(completion: @escaping (Date?) -> ()) {
        matches.mapValues({ try $0.endOfLastMatch().unwrap() }).retrieve { (result) in
            completion(result.value?.addingTimeInterval(86400))
        }
    }
    
    public func matches(after date: Date, limit: Int, completion: @escaping ([MatchSnapshot]?) -> ()) {
        matches.retrieve { (result) in
            if let matches = result.value {
                let matchesAfter = matches.snapshots().after(date)
                let realLimit = min(limit, matchesAfter.count)
                completion(Array(matchesAfter.prefix(upTo: realLimit)))
            } else {
                completion(nil)
            }
        }
    }
    
    public func currentMatch(completion: @escaping (MatchSnapshot?) -> ()) {
        matches.retrieve { (result) in
            if let matches = result.value {
                let matchesBefore = matches.snapshots().before(Date())
                completion(matchesBefore.last)
            } else {
                completion(nil)
            }
        }
    }
    
    public func matches(before date: Date, limit: Int, completion: @escaping ([MatchSnapshot]?) -> ()) {
        matches.retrieve { (result) in
            if let matches = result.value {
                let matchesBefore = matches.snapshots().before(date)
                let realLimit = min(limit, matchesBefore.count)
                completion(Array(matchesBefore.prefix(upTo: realLimit)))
            } else {
                completion(nil)
            }
        }
    }
    
    public lazy var placeholderMatch: Match.Full = self.makePlaceholderMatch(for: Locale.current)
    
    private func makePlaceholderMatch(for locale: Locale) -> Match.Full {
        if let region = locale.regionCode {
            switch region {
            case "RU", "UA", "BY":
                return makePlaceholderMatchRUS()
            default:
                return makeDefaultPlaceholderMatch()
            }
        }
        return makeDefaultPlaceholderMatch()
    }
    
    private func makeDefaultPlaceholderMatch() -> Match.Full {
        let home = Match.Team(id: Team.ID.init(rawValue: -1)!, name: "Germany", shortName: "GER", badgeURL: URL(string: "https://goo.gl")!)
        let away = Match.Team(id: Team.ID.init(rawValue: -1)!, name: "Sweden", shortName: "SWE", badgeURL: URL(string: "https://goo.gl")!)
        return makeMatch(teams: (home, away), score: (1, 1))
    }
    
    private func makePlaceholderMatchRUS() -> Match.Full {
        let home = Match.Team(id: Team.ID.init(rawValue: -1)!, name: "Russia", shortName: "RUS", badgeURL: URL(string: "https://goo.gl")!)
        let away = Match.Team(id: Team.ID.init(rawValue: -1)!, name: "Germany", shortName: "GER", badgeURL: URL(string: "https://goo.gl")!)
        return makeMatch(teams: (home, away), score: (2, 0))
    }
    
    private func makeMatch(teams: (Match.Team, Match.Team), score: (Int, Int)?) -> Match.Full {
        let scorescore = score.map({ Match.Score.init(home: $0.0, away: $0.1) })
        return Match.Full(id: Match.ID.init(rawValue: -1)!, home: teams.0, away: teams.1, date: Date(), endDate: Date().addingTimeInterval(60 * 120), location: "Netherlands", stageTitle: "Group Stage", score: scorescore, events: [])
    }
    
}

internal extension Array where Element == ComplicationDataSource.MatchSnapshot {
    
    func after(_ date: Date) -> [ComplicationDataSource.MatchSnapshot] {
        return Array(self.drop(while: { $0.timelineDate < date }))
    }
    
    func before(_ date: Date) -> [ComplicationDataSource.MatchSnapshot] {
        return Array(self.prefix(while: { $0.timelineDate < date }))
    }
    
}

internal extension Sequence where Iterator.Element == Match.Full {
    
    func removingStartingAtTheSameDate(with decide: (Match.Full, Match.Full) -> Match.Full) -> [Iterator.Element] {
        var dates: [Date: Match.Full] = [:]
        for match in self {
            let date = match.date
            if let conflicting = dates[date] {
                dates[date] = decide(conflicting, match)
            } else {
                dates[date] = match
            }
        }
        return dates.map({ $0.value }).sortedByDate()
    }
    
    func timelineStartDate() -> Date? {
        if let first = self.firstStartDate() {
            return Swift.min(Date().startOfSameDay(), first.startOfSameDay())
        } else {
            return nil
        }
    }
    
    func snapshots() -> [ComplicationDataSource.MatchSnapshot] {
        return flatMap({ (match) -> [ComplicationDataSource.MatchSnapshot] in
            let beforeStart = ComplicationDataSource.MatchSnapshot.init(match: match.notStartedSnapshot(), timelineDate: assumeSortedTimelineDate(for: match))
            let otherSnapshots = match.allSnapshots()
                .map({ ComplicationDataSource.MatchSnapshot.init(match: $0.0, timelineDate: $0.0.date(afterMinutesFromStart: $0.minute)) })
            var all = [beforeStart]
            all.append(contentsOf: otherSnapshots)
            return all
        })
    }
    
    func assumeSortedTimelineDate(for givenMatch: Match.Full) -> Date {
        var previous: Match.Full? = nil
        for match in self {
            if match.id == givenMatch.id {
                if let previous = previous {
                    return Swift.max(previous.endDate.addingTimeInterval(Match.aftermath), givenMatch.date.startOfSameDay())
                } else {
                    return Swift.min(Date().startOfSameDay(), givenMatch.date.startOfSameDay())
                }
            }
            previous = match
        }
        return Swift.min(Date().startOfSameDay(), givenMatch.date.startOfSameDay())
    }
    
}

extension Date {
    
    internal func startOfSameDay() -> Date {
        return Calendar.current.startOfDay(for: self)
    }
    
}

extension Sequence where Iterator.Element : MatchProtocol {
    
    func ongoingMatches(for date: Date) -> [Iterator.Element] {
        return filter({ date > $0.date || date < $0.endDate })
    }
    
    func sortedByDate() -> [Iterator.Element] {
        return sorted(by: { $0.date < $1.date })
    }
    
    func firstStartDate() -> Date? {
        return self.min(by: { $0.date < $1.date })?.date
    }
    
    func endOfLastMatch() -> Date? {
        return self.max(by: { $0.date < $1.date })?.endDate
    }
    
}
