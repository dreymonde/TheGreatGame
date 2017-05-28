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
        if let val = res.asOptional {
            completion(val)
        }
    }
}

func asOptional<T>(_ completion: @escaping (T?) -> ()) -> (Result<T>) -> () {
    return { completion($0.asOptional) }
}

public final class ComplicationDataSource {
    
    public struct Mtch {
        public let match: Match.Compact
        public let timelineDate: Date
        
        public init(match: Match.Compact, timelineDate: Date) {
            self.match = match
            self.timelineDate = timelineDate
        }
    }
    
    public let matches: ReadOnlyCache<Void, [Match.Compact]>
    
    public init(provider: ReadOnlyCache<Void, [Match.Compact]>) {
        self.matches = provider
    }
    
    public func timelineStartDate(completion: @escaping (Date?) -> ()) {
        matches.retrieve { (result) in
            completion(result.asOptional?.timelineStartDate())
        }
    }
    
    public func timelineEndDate(completion: @escaping (Date?) -> ()) {
        matches.mapValues({ try $0.endOfLastMatch().unwrap() }).retrieve { (result) in
            completion(result.asOptional?.addingTimeInterval(86400))
        }
    }
    
    public func matches(after date: Date, limit: Int, completion: @escaping ([Mtch]?) -> ()) {
        matches.retrieve { (result) in
            if let matches = result.asOptional {
                let matchesAfter = matches.after(date)
                let realLimit = min(limit, matchesAfter.count)
                completion(Array(matchesAfter.prefix(upTo: realLimit)))
            } else {
                completion(nil)
            }
        }
    }
    
    public func matches(before date: Date, limit: Int, completion: @escaping ([Mtch]?) -> ()) {
        matches.retrieve { (result) in
            if let matches = result.asOptional {
                let matchesBefore = matches.before(date)
                let realLimit = min(limit, matchesBefore.count)
                completion(Array(matchesBefore.prefix(upTo: realLimit)))
            } else {
                completion(nil)
            }
        }
    }
    
    private func timelineDate(forMatch match: Match.Compact, in matches: [Match.Compact]) -> Date {
        return previousMatch(forMatch: match, in: matches)?.date.addingTimeInterval(Match.durationAndAftermath) ?? matches.timelineStartDate() ?? Date()
    }
    
    private func previousMatch(forMatch match: Match.Compact, in matches: [Match.Compact]) -> Match.Compact? {
        if let index = matches.index(where: { $0.id == match.id }) {
            if index == 0 { return nil }
            return matches[index - 1]
        }
        return nil
    }
    
}

internal extension Sequence where Iterator.Element == Match.Compact {
    
    func timelineStartDate() -> Date? {
        if let first = self.firstStartDate() {
            return Swift.min(Date().startOfSameDay(), first.startOfSameDay())
        } else {
            return nil
        }
    }
    
    func after(_ date: Date) -> [ComplicationDataSource.Mtch] {
        return Array(sortedByDate()
            .map({ ComplicationDataSource.Mtch.init(match: $0, timelineDate: timelineDate(for: $0)) })
            .drop(while: { $0.timelineDate < date }))
    }
    
    func before(_ date: Date) -> [ComplicationDataSource.Mtch] {
        return Array(sortedByDate()
            .map({ ComplicationDataSource.Mtch.init(match: $0, timelineDate: timelineDate(for: $0)) })
            .prefix(while: { $0.timelineDate < date }))
    }
    
    func timelineDate(for givenMatch: Match.Compact) -> Date {
        let sortedMatches = self.sortedByDate()
        var previous: Match.Compact? = nil
        for match in sortedMatches {
            if match.id == givenMatch.id {
                return previous?.date.addingTimeInterval(Match.durationAndAftermath) ?? Swift.min(Date().startOfSameDay(), givenMatch.date.startOfSameDay())
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

extension Sequence where Iterator.Element : HasStartDate {
    
    func ongoingMatches(for date: Date) -> [Iterator.Element] {
        return filter({ date > $0.date || date < $0.date.addingTimeInterval(Match.durationAndAftermath) })
    }
    
    func sortedByDate() -> [Iterator.Element] {
        return sorted(by: { $0.date < $1.date })
    }
    
    func firstStartDate() -> Date? {
        return self.min(by: { $0.date < $1.date })?.date
    }
    
    func endOfLastMatch() -> Date? {
        return self.max(by: { $0.date < $1.date })?.date.addingTimeInterval(Match.duration)
    }
    
}
