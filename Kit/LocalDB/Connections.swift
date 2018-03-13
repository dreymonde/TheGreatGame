//
//  Connections.swift
//  TheGreatGame
//
//  Created by Олег on 28.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public final class Connections {
    
    private let api: API
    private let localDB: LocalDB
    
    public let teams: APIFireUpdate<[Team.Compact]>
    public let stages: APIFireUpdate<[Stage]>
    public let groups: APIFireUpdate<[Group.Compact]>
    public let fullMatches: APIFireUpdate<[Match.Full]>
    
    private let activityIndicator: NetworkActivityIndicator
    
    public init(api: API, localDB: LocalDB, activityIndicator: NetworkActivityIndicator) {
        self.api = api
        self.localDB = localDB
        self.activityIndicator = activityIndicator
        self.teams = APIFireUpdate(retrieve: api.teams.all.mapValues({ $0.content.teams }),
                                   write: localDB.teams.set,
                                   activityIndicator: activityIndicator)
        self.stages = APIFireUpdate(retrieve: api.matches.stages.mapValues({ $0.content.stages }),
                                    write: localDB.stages.set,
                                    activityIndicator: activityIndicator)
        self.groups = APIFireUpdate(retrieve: api.groups.all.mapValues({ $0.content.groups }),
                                    write: localDB.groups.set,
                                    activityIndicator: activityIndicator)
        self.fullMatches = APIFireUpdate(retrieve: api.matches.allFull.mapValues({ $0.content.matches }),
                                         write: localDB.fullMatches.set,
                                         activityIndicator: activityIndicator)
    }
    
    public func fullTeam(id: Team.ID) -> APIFireUpdate<Team.Full> {
        return APIFireUpdate(retrieve: api.teams.fullTeam.singleKey(id).mapValues({ $0.content }),
                             write: localDB.fullTeam(id).set,
                             activityIndicator: activityIndicator)
    }
    
    public func fullMatch(id: Match.ID) -> APIFireUpdate<Match.Full> {
        return APIFireUpdate(retrieve: api.matches.fullMatch.singleKey(id).mapValues({ $0.content }),
                             write: localDB.fullMatch(id).set,
                             activityIndicator: activityIndicator)
    }
    
}
