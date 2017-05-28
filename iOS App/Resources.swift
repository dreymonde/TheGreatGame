//
//  Storage.swift
//  TheGreatGame
//
//  Created by Олег on 23.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public final class Resources {
    
    public var stages: Resource<[Stage]>
    public var teams: Resource<[Team.Compact]>
    public var groups: Resource<[Group.Compact]>
    
    public var fullTeam: (Team.ID) -> Resource<Team.Full>
    
    public var all: [Prefetchable] {
        return [stages, teams, groups]
    }
    
    public func prefetchAll() {
        all.forEach({ $0.prefetch() })
    }
    
    public init(stages: Resource<[Stage]>, teams: Resource<[Team.Compact]>, groups: Resource<[Group.Compact]>, fullTeam: @escaping (Team.ID) -> Resource<Team.Full>) {
        self.stages = stages
        self.teams = teams
        self.groups = groups
        self.fullTeam = fullTeam
    }
    
}

extension Resources {
    
    public convenience init(api: API, apiCache: APICache, networkActivity: NetworkActivityIndicatorManager) {
        self.init(stages: Resources.makeStagesResource(api: api, apiCache: apiCache, networkActivity: networkActivity),
                  teams: Resources.makeTeamsResource(api: api, apiCache: apiCache, networkActivity: networkActivity),
                  groups: Resources.makeGroupsResource(api: api, apiCache: apiCache, networkActivity: networkActivity),
                  fullTeam: Resources.makeFullTeamsResources(api: api, apiCache: apiCache, networkActivity: networkActivity))
    }
    
    public static func makeStagesResource(api: API, apiCache: APICache, networkActivity: NetworkActivityIndicatorManager) -> Resource<[Stage]> {
        return Resource<Stages>(local: apiCache.matches.stages,
                                remote: api.matches.stages,
                                networkActivity: networkActivity)
            .map({ $0.stages })
    }
    
    public static func makeTeamsResource(api: API, apiCache: APICache, networkActivity: NetworkActivityIndicatorManager) -> Resource<[Team.Compact]> {
        return Resource<Teams>(local: apiCache.teams.all,
                               remote: api.teams.all,
                               networkActivity: networkActivity)
            .map({ $0.teams })
    }
    
    public static func makeGroupsResource(api: API, apiCache: APICache, networkActivity: NetworkActivityIndicatorManager) -> Resource<[Group.Compact]> {
        return Resource<Groups>(local: apiCache.groups.all,
                                remote: api.groups.all,
                                networkActivity: networkActivity)
            .map({ $0.groups })
    }
    
    public static func makeFullTeamsResources(api: API, apiCache: APICache, networkActivity: NetworkActivityIndicatorManager) -> (Team.ID) -> Resource<Team.Full> {
        var existing: [Team.ID : Resource<Team.Full>] = [:]
        let safety = DispatchQueue(label: "resources-pool-safety-queue")
        return { id in
            return safety.sync {
                if let already = existing[id] {
                    return already
                } else {
                    let new = Resource<Team.Full>(local: apiCache.teams.fullTeam.singleKey(id),
                                                  remote: api.teams.fullTeam.singleKey(id),
                                                  networkActivity: networkActivity)
                    existing[id] = new
                    return new
                }
            }
        }
    }
    
}
