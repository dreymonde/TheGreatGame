//
//  API.swift
//  TheGreatGame
//
//  Created by Олег on 07.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public protocol APIProvider {
    
    init(dataProvider: ReadOnlyCache<String, Data>)
    
}

internal protocol APIPoint : APIProvider {
    
}

internal protocol APICachePoint {
    
    init(dataProvider: Cache<String, Data>)
    
}

extension APIProvider {
    
    public static func gitHub(networkCache: ReadOnlyCache<URL, Data> = Self.makeUrlSessionCache()) -> Self {
        let gitRepo = GitHubRepo.theGreatGameStorage(networkCache: networkCache)
        return Self(dataProvider: gitRepo.asReadOnlyCache())
    }
    
    public static func heroku(networkCache: ReadOnlyCache<URL, Data> = Self.makeUrlSessionCache()) -> Self {
        let baseURL = URL(string: "https://the-great-game-ruby.herokuapp.com")!
        let subcache: ReadOnlyCache<String, Data> = networkCache
            .mapKeys({ URL.init(string: $0, relativeTo: baseURL)! })
        return Self(dataProvider: subcache)
    }
    
    public static func gitHub(urlSession: URLSession) -> Self {
        let sessionCache = Self.makeUrlSessionCache(from: urlSession)
        return Self.gitHub(networkCache: sessionCache)
    }
    
    public static func macBookSteve() -> Self {
        let directory = "/Users/oleg/Development/TheGreatGame/Storage" <* URL.init(fileURLWithPath:)
        let rawFS = RawFileSystemCache(directoryURL: directory)
            .mapKeys(RawFileSystemCache.FileName.init)
        let cache = rawFS
            .asReadOnlyCache()
            .latency(ofInterval: 1.0)
        return Self(dataProvider: cache)
    }
    
    internal static func makeUrlSessionCache(from session: URLSession = .init(configuration: .default)) -> ReadOnlyCache<URL, Data> {
        return URLSession(configuration: .default)
            .asReadOnlyCache()
            .droppingResponse()
            .usingURLKeys()
    }
    
}

public final class API : APIProvider {
    
    public let teams: TeamsAPI
    public let matches: MatchesAPI
    public let groups: GroupsAPI
    
    public init(teams: TeamsAPI, matches: MatchesAPI, groups: GroupsAPI) {
        self.teams = teams
        self.matches = matches
        self.groups = groups
    }
    
    public convenience init(dataProvider: ReadOnlyCache<String, Data>) {
        let teamsAPI = TeamsAPI.init(dataProvider: dataProvider)
        let matchesAPI = MatchesAPI.init(dataProvider: dataProvider)
        let groupsAPI = GroupsAPI.init(dataProvider: dataProvider)
        self.init(teams: teamsAPI, matches: matchesAPI, groups: groupsAPI)
    }
    
}

public final class APICache : Storing {
    
    public static var preferredSubPath: String {
        return "api-cache-10"
    }
    
    public let teams: TeamsAPICache
    public let matches: MatchesAPICache
    public let groups: GroupsAPICache
    
    public init(teams: TeamsAPICache, matches: MatchesAPICache, groups: GroupsAPICache) {
        self.teams = teams
        self.matches = matches
        self.groups = groups
    }
    
    public convenience init(diskCache cache: Cache<String, Data>) {
        self.init(teams: TeamsAPICache.init(dataProvider: cache),
                  matches: MatchesAPICache.init(dataProvider: cache),
                  groups: GroupsAPICache.init(dataProvider: cache))
    }

}

extension ReadOnlyCache {
    
    public func latency(ofInterval interval: TimeInterval) -> ReadOnlyCache<Key, Value> {
        return ReadOnlyCache(cacheName: self.cacheName) { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: {
                    completion(result)
                })
            })
        }
    }
    
}
