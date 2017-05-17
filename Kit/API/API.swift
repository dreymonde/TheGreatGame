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
    
    init(networkProvider: ReadOnlyCache<String, Data>)
    
}

extension APIPoint {
    
    public static func gitHub(networkCache: ReadOnlyCache<URL, Data> = Self.makeUrlSessionCache()) -> Self {
        let gitRepo = GitHubRepo.theGreatGameStorage(networkCache: networkCache)
        return Self(networkProvider: gitRepo.asReadOnlyCache())
    }
    
    public static func macBookSteve() -> Self {
        let directory = "/Users/oleg/Development/TheGreatGame/Storage" <* URL.init(fileURLWithPath:)
        let rawFS = RawFileSystemCache(directoryURL: directory)
            .mapKeys(RawFileSystemCache.FileName.init)
        let cache = ReadOnlyCache(cacheName: rawFS.cacheName) { (key, completion) in
            rawFS.retrieve(forKey: key, completion: { (result) in
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: { 
                    completion(result)
                })
            })
        }
        return Self(networkProvider: cache)
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
    public let groups: GroupsAPI
    
    public init(teams: TeamsAPI, matches: MatchesAPI, groups: GroupsAPI) {
        self.teams = teams
        self.matches = matches
        self.groups = groups
    }
    
    public static func gitHub(urlSession: URLSession) -> API {
        let sessionCache = urlSession
            .asReadOnlyCache()
            .droppingResponse()
            .usingURLKeys()
        let teamsAPI = TeamsAPI.gitHub(networkCache: sessionCache)
        let matchesAPI = MatchesAPI.gitHub(networkCache: sessionCache)
        let groupsAPI = GroupsAPI.gitHub(networkCache: sessionCache)
        return API(teams: teamsAPI, matches: matchesAPI, groups: groupsAPI)
    }
    
    public static func macBookSteve() -> API {
        return API(teams: .macBookSteve(),
                   matches: .macBookSteve(),
                   groups: .macBookSteve())
    }
    
}
