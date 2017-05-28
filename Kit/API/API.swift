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
    
    init(dataProvider: ReadOnlyCache<String, Data>)
    
}

internal protocol APICachePoint {
    
    init(dataProvider: Cache<String, Data>)
    
}

extension APIPoint {
    
    public static func gitHub(networkCache: ReadOnlyCache<URL, Data> = Self.makeUrlSessionCache()) -> Self {
        let gitRepo = GitHubRepo.theGreatGameStorage(networkCache: networkCache)
        return Self(dataProvider: gitRepo.asReadOnlyCache())
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
        return Self(dataProvider: cache)
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

public final class APICache {
    
    public let teams: TeamsAPICache
    public let matches: MatchesAPICache
    public let groups: GroupsAPICache
    
    public init(teams: TeamsAPICache, matches: MatchesAPICache, groups: GroupsAPICache) {
        self.teams = teams
        self.matches = matches
        self.groups = groups
    }
    
    public convenience init(cache: Cache<String, Data>) {
        self.init(teams: TeamsAPICache.init(dataProvider: cache),
                  matches: MatchesAPICache.init(dataProvider: cache),
                  groups: GroupsAPICache.init(dataProvider: cache))
    }
    
    public static func dev() -> APICache {
        printWithContext("Caching API to disk disabled")
        let sharedDataLayer = NSCacheCache<NSString, NSData>()
            .toNonObjCKeys()
            .mapValues(transformIn: { $0 as Data },
                       transformOut: { $0 as NSData })
        return APICache(cache: sharedDataLayer)
    }
    
    public static func inLocalCachesDirectory() -> APICache {
        let fs = FileSystemCache.inDirectory(.cachesDirectory, appending: "watch-cache-1")
        let sharedDataLayer = NSCacheCache<NSString, NSData>()
            .toNonObjCKeys()
            .mapValues(transformIn: { $0 as Data },
                       transformOut: { $0 as NSData })
            .combined(with: fs)
        return APICache(cache: sharedDataLayer)
    }
    
    public static func inSharedCachesDirectory() -> APICache {
        let fs = FileSystemCache.inSharedContainer(subpath: .caches(appending: "api-cache-mnt-1"), qos: .userInteractive)
        let sharedDataLayer = NSCacheCache<NSString, NSData>()
            .toNonObjCKeys()
            .mapValues(transformIn: { $0 as Data },
                       transformOut: { $0 as NSData })
            .combined(with: fs)
        return APICache(cache: sharedDataLayer)
    }
    
}
