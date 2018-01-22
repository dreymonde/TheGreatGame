//
//  LocalDB.swift
//  TheGreatGame
//
//  Created by Олег on 27.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public final class LocalDB : DeepStoring {
    
    public typealias PreferredDirectory = Library.Application_Support.db
    
    public static func preferredDirectory(from base: BaseFolder.Type) -> Library.Application_Support.db {
        return base.Library.Application_Support.db
    }
    
    public static var filenameEncoder: Filename.Encoder {
        return .noEncoding
    }
    
    public let teams: LocalModel<[Team.Compact]>
    public let stages: LocalModel<[Stage]>
    public let groups: LocalModel<[Group.Compact]>
    
    public let fullMatches: LocalModel<[Match.Full]>
    
    public let fullTeam: (Team.ID) -> LocalModel<Team.Full>
    public let fullMatch: (Match.ID) -> LocalModel<Match.Full>
    
    public init(teams: LocalModel<[Team.Compact]>,
                stages: LocalModel<[Stage]>,
                groups: LocalModel<[Group.Compact]>,
                fullMatches: LocalModel<[Match.Full]>,
                fullTeam: @escaping (Team.ID) -> LocalModel<Team.Full>,
                fullMatch: @escaping (Match.ID) -> LocalModel<Match.Full>) {
        self.teams = teams
        self.stages = stages
        self.groups = groups
        self.fullMatches = fullMatches
        self.fullTeam = fullTeam
        self.fullMatch = fullMatch
    }
    
    public func prefetchAll() {
        teams.prefetch()
        stages.prefetch()
    }
    
    public convenience init(container: Container) {
        let teams: LocalModel<[Team.Compact]> = LocalModel<[Team.Compact]>.inStorage(LocalDB.substorage(in: container, subFolder: { $0.teams }), filename: "teams-compact")
        let stages: LocalModel<[Stage]> = LocalModel<[Stage]>.inStorage(LocalDB.substorage(in: container, subFolder: { $0.stages }), filename: "stages")
        let groups: LocalModel<[Group.Compact]> = LocalModel<[Group.Compact]>.inStorage(LocalDB.substorage(in: container, subFolder: { $0.groups }), filename: "all-groups")
        let matches: LocalModel<[Match.Full]> = LocalModel<[Match.Full]>.inStorage(LocalDB.substorage(in: container, subFolder: { $0.matches }), filename: "matches-full")
        let fullTeam = LocalDB.makeFullTeam(makeStorage: { produce in LocalDB.substorage(in: container, subFolder: produce) })
        let fullMatch = LocalDB.makeFullMatch(makeStorage: { produce in LocalDB.substorage(in: container, subFolder: produce) })
        self.init(teams: teams,
                  stages: stages,
                  groups: groups,
                  fullMatches: matches,
                  fullTeam: fullTeam,
                  fullMatch: fullMatch)
    }
    
}

extension LocalDB {
    
    public static func inContainer(_ container: Container) -> LocalDB {
        return LocalDB(container: container)
    }
    
}

extension LocalDB {

    static func makeLazy<IDType : Hashable, Value : Mappable>(storage: Disk,
                                                              makeFilename: @escaping (IDType) -> Filename) -> (IDType) -> LocalModel<Value> {
        let lazyDict = LazyDictionary<IDType, LocalModel<Value>> { id in
            return LocalModel<Value>.inStorage(storage, filename: makeFilename(id))
        }
        let tsLazyDict = ThreadSafe(lazyDict)
        return { id in
            return tsLazyDict.read()[id]
        }
    }

    static func makeFullTeam(makeStorage: ((PreferredDirectory) -> (Directory)) -> Disk) -> (Team.ID) -> LocalModel<Team.Full> {
        return makeLazy(storage: makeStorage({ $0.teams }),
                        makeFilename: { Filename.init(rawValue: "team-\($0)") })
    }

    static func makeFullMatch(makeStorage: ((PreferredDirectory) -> (Directory)) -> Disk) -> (Match.ID) -> LocalModel<Match.Full> {
        return makeLazy(storage: makeStorage({ $0.matches }),
                        makeFilename: { Filename.init(rawValue: "match-\($0)") })
    }

}

