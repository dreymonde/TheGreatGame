//
//  Storage.swift
//  TheGreatGame
//
//  Created by Олег on 23.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import TheGreatKit
import Shallows

final class Resources {
    
    var stages: Resource<[Stage]>
    var teams: Resource<[Team.Compact]>
    var groups: Resource<[Group.Compact]>
    
    var fullTeam: (Team.ID) -> Resource<Team.Full>
    
    var all: [Prefetchable] {
        return [stages, teams, groups]
    }
    
    func prefetchAll() {
        all.forEach({ $0.prefetch() })
    }
    
    init(stages: Resource<[Stage]>, teams: Resource<[Team.Compact]>, groups: Resource<[Group.Compact]>, fullTeam: @escaping (Team.ID) -> Resource<Team.Full>) {
        self.stages = stages
        self.teams = teams
        self.groups = groups
        self.fullTeam = fullTeam
    }
    
}

extension Resources {
    
    convenience init(application: Application) {
        self.init(stages: Resources.makeStagesResource(application: application),
                  teams: Resources.makeTeamsResource(application: application),
                  groups: Resources.makeGroupsResource(application: application),
                  fullTeam: Resources.makeFullTeamsResources(application: application))
    }
    
    private static func makeStagesResource(application: Application) -> Resource<[Stage]> {
        return Resource<Stages>(local: application.apiCache.matches.stages,
                                remote: application.api.matches.stages)
            .map({ $0.stages })
    }
    
    private static func makeTeamsResource(application: Application) -> Resource<[Team.Compact]> {
        return Resource<Teams>(local: application.apiCache.teams.all,
                               remote: application.api.teams.all)
            .map({ $0.teams })
    }
    
    private static func makeGroupsResource(application: Application) -> Resource<[Group.Compact]> {
        return Resource<Groups>(local: application.apiCache.groups.all,
                                remote: application.api.groups.all)
            .map({ $0.groups })
    }
    
    private static func makeFullTeamsResources(application: Application) -> (Team.ID) -> Resource<Team.Full> {
        var existing: [Team.ID : Resource<Team.Full>] = [:]
        let safety = DispatchQueue(label: "resources-pool-safety-queue")
        return { id in
            return safety.sync {
                if let already = existing[id] {
                    return already
                } else {
                    let new = Resource<Team.Full>(local: application.apiCache.teams.fullTeam.singleKey(id),
                                                  remote: application.api.teams.fullTeam.singleKey(id))
                    existing[id] = new
                    return new
                }
            }
        }
    }
    
}
