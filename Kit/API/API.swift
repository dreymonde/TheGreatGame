//
//  API.swift
//  TheGreatGame
//
//  Created by Олег on 07.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

internal protocol APIPoint {
    
    init(rawDataProvider: ReadOnlyCache<String, Data>)
    
}

extension APIPoint {
    
    public static func gitHub(networkCache: ReadOnlyCache<URL, Data> = Self.makeUrlSessionCache()) -> Self {
        let gitRepo = GitHubRepo.theGreatGameStorage(networkCache: networkCache)
        return Self(rawDataProvider: gitRepo.asReadOnlyCache())
    }
    
    internal static func makeUrlSessionCache() -> ReadOnlyCache<URL, Data> {
        return URLSession(configuration: .default)
            .asReadOnlyCache()
            .droppingResponse()
            .usingURLKeys()
    }
    
}

public final class API {
    
    public let teams: TeamsAPI
    public let matches: MatchesAPI
    
    public init(teams: TeamsAPI, matches: MatchesAPI) {
        self.teams = teams
        self.matches = matches
    }
    
    public static func gitHub(urlSession: URLSession) -> API {
        let sessionCache = urlSession
            .asReadOnlyCache()
            .droppingResponse()
            .usingURLKeys()
        let teamsAPI = TeamsAPI.gitHub(networkCache: sessionCache)
        let matchesAPI = MatchesAPI.gitHub(networkCache: sessionCache)
        return API(teams: teamsAPI, matches: matchesAPI)
    }
    
}
