//
//  LocalDB.swift
//  TheGreatGame
//
//  Created by Олег on 27.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public final class LocalDB {
    
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
    
    public convenience init(dbFolder: db_dir, makeStorage: (SubpathName) -> DiskStorage) {
        let teams: LocalModel<[Team.Compact]> = {
            let folder = dbFolder.teams
            let storage = makeStorage(folder)
            return LocalModel<[Team.Compact]>.inStorage(storage, filename: "teams-compact")
        }()
        let stages: LocalModel<[Stage]> = {
            let folder = dbFolder.stages
            let storage = makeStorage(folder)
            return LocalModel<[Stage]>.inStorage(storage, filename: "stages")
        }()
        let groups: LocalModel<[Group.Compact]> = {
            let folder = dbFolder.groups
            let storage = makeStorage(folder)
            return LocalModel<[Group.Compact]>.inStorage(storage, filename: "all-groups")
        }()
        let matches: LocalModel<[Match.Full]> = {
            let folder = dbFolder.matches
            let storage = makeStorage(folder)
            return LocalModel<[Match.Full]>.inStorage(storage, filename: "matches-full")
        }()
        let fullTeam = LocalDB.makeFullTeam(dbFolder: dbFolder, makeStorage: makeStorage)
        let fullMatch = LocalDB.makeFullMatch(dbFolder: dbFolder, makeStorage: makeStorage)
        self.init(teams: teams,
                  stages: stages,
                  groups: groups,
                  fullMatches: matches,
                  fullTeam: fullTeam,
                  fullMatch: fullMatch)
    }
    
}

extension LocalDB {
    
    public static func inSharedDocumentsFolder() -> LocalDB {
        return LocalDB(dbFolder: FolderStructure.data.db, makeStorage: { (subpath) -> DiskStorage in
            return DiskStorage.inSharedDocuments(appending: subpath)
        })
    }
    
    public static func inLocalDocumentsFolder() -> LocalDB {
        return LocalDB(dbFolder: FolderStructure.data.db, makeStorage: { (subpath) -> DiskStorage in
            return DiskStorage.inLocalDocuments(appending: subpath)
        })
    }
    
    public static func inSharedCachesFolder() -> LocalDB {
        return LocalDB(dbFolder: FolderStructure.data.db, makeStorage: { (subpath) -> DiskStorage in
            return DiskStorage.inSharedCaches(appending: subpath)
        })
    }
    
}

extension LocalDB {
    
    static func makeLazy<IDType : Hashable, Value : Mappable>(subpath: SubpathName,
                                                   makeFilename: @escaping (IDType) -> Filename,
                                                   makeStorage: (SubpathName) -> DiskStorage) -> (IDType) -> LocalModel<Value> {
        let storage = makeStorage(subpath)
        let lazyDict = LazyDictionary<IDType, LocalModel<Value>> { id in
            return LocalModel<Value>.inStorage(storage, filename: makeFilename(id))
        }
        let tsLazyDict = ThreadSafe(lazyDict)
        return { id in
            return tsLazyDict.read()[id]
        }
    }
    
    static func makeFullTeam(dbFolder: db_dir, makeStorage: (SubpathName) -> DiskStorage) -> (Team.ID) -> LocalModel<Team.Full> {
        return makeLazy(subpath: dbFolder.teams,
                        makeFilename: { Filename.init(rawValue: "team-\($0)") },
                        makeStorage: makeStorage)
    }
    
    static func makeFullMatch(dbFolder: db_dir, makeStorage: (SubpathName) -> DiskStorage) -> (Match.ID) -> LocalModel<Match.Full> {
        return makeLazy(subpath: dbFolder.matches,
                        makeFilename: { Filename.init(rawValue: "match-\($0)") },
                        makeStorage: makeStorage)
    }
    
}
