//
//  ComplicationDataSource.swift
//  TheGreatGame
//
//  Created by Олег on 28.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public final class ComplicationDataSource {
    
    public struct MatchSnapshot {
        public var match: Match.Full
        public var timelineDate: Date
        public var aforetime: Bool
        
        public init(match: Match.Full, timelineDate: Date, aforetime: Bool = false) {
            self.match = match
            self.timelineDate = timelineDate
            self.aforetime = aforetime
        }
    }
    
    public let matches: Retrieve<[Match.Full]>
    public let conflictResolver: (Match.Full, Match.Full) -> Match.Full
    
    public init(provider: Retrieve<[Match.Full]>,
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
        completion(Date.distantFuture)
    }
    
    public func matches(after date: Date, limit: Int, completion: @escaping ([MatchSnapshot]?) -> ()) {
        matches.retrieve { (result) in
            if let matches = result.value {
                let matchesAfter = matches.snapshots().after(date)
                completion(Array(matchesAfter.prefix(limit)))
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
                completion(Array(matchesBefore.suffix(limit)))
            } else {
                completion(nil)
            }
        }
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
                printWithContext("Conflicting matches: \(conflicting.id) vs \(match.id)")
                let decided = decide(conflicting, match)
                printWithContext("Choosing \(decided.id)")
                dates[date] = decided
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
        var allMatchesSnapshots = flatMap({ (match) -> [ComplicationDataSource.MatchSnapshot] in
            let minTimelineDate = assumeSortedTimelineDate(for: match)
            let beforeStart = ComplicationDataSource.MatchSnapshot.init(match: match.notStartedSnapshot(), timelineDate: minTimelineDate)
            let otherSnapshots = match.allSnapshots()
                .map({ ComplicationDataSource.MatchSnapshot(match: $0.match,
                                                            timelineDate: Swift.max($0.match.date(afterRealMinutesFromStart: $0.minute), minTimelineDate)) })
            var all = [beforeStart]
            all.append(contentsOf: otherSnapshots)
            return all
        })
        if let first = allMatchesSnapshots.first {
            let aforetime = modified(first) { (f: inout ComplicationDataSource.MatchSnapshot) in
                f.aforetime = true
                f.timelineDate = Date(timeIntervalSince1970: 1498949847)
            }
            allMatchesSnapshots.insert(aforetime, at: 0)
        }
        return allMatchesSnapshots
    }
    
    func assumeSortedTimelineDate(for givenMatch: Match.Full) -> Date {
        var previous: Match.Full? = nil
        for match in self {
            if match.id == givenMatch.id {
                if let previous = previous {
                    return Swift.max(previous.endDate.addingTimeInterval(Match.aftermath), givenMatch.date.startOfSameDay())
                } else {
                    return givenMatch.date.startOfSameDay()
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

extension Match {
    
    public static func endsLater<MatchType : MatchProtocol>(_ lhs: MatchType, _ rhs: MatchType) -> MatchType {
        if lhs.endDate > rhs.endDate {
            return lhs
        }
        return rhs
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
