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
    
    init(dataProvider: ReadOnlyStorage<APIPath, Data>)
    
}

internal protocol APIPoint : APIProvider {
    
}

extension APIProvider {
    
    public static func gitHub(networkCache: ReadOnlyStorage<URL, Data> = Self.makeUrlSessionCache()) -> Self {
        let gitRepo: ReadOnlyStorage<APIPath, Data> = GitHubRepo.theGreatGameStorage(networkCache: networkCache).asReadOnlyStorage()
            .mapKeys({ return "content" + $0 })
        return Self(dataProvider: gitRepo)
    }
    
    public static func gitHubRaw(networkCache: ReadOnlyStorage<URL, Data> = Self.makeUrlSessionCache()) -> Self {
        let gitRawRepo: ReadOnlyStorage<APIPath, Data> = GitHubRawFilesRepo.theGreatGameStorage(networkCache: networkCache).asReadOnlyStorage()
        return Self(dataProvider: gitRawRepo)
    }
    
    public static func heroku(networkCache: ReadOnlyStorage<URL, Data> = Self.makeUrlSessionCache()) -> Self {
        let baseURL = URL(string: "https://the-great-game-ruby.herokuapp.com")!
        let subcache: ReadOnlyStorage<APIPath, Data> = WebAPI(networkProvider: networkCache, baseURL: baseURL).asReadOnlyStorage()
        return Self(dataProvider: subcache)
    }
    
    public static func digitalOcean(networkCache: ReadOnlyStorage<URL, Data> = Self.makeUrlSessionCache()) -> Self {
        let baseURL = Server.digitalOceanStorageBaseURL
        let subcache: ReadOnlyStorage<APIPath, Data> = WebAPI(networkProvider: networkCache, baseURL: baseURL).asReadOnlyStorage()
        return Self(dataProvider: subcache)
    }
    
    public static func gitHub(urlSession: URLSession) -> Self {
        let sessionCache = Self.makeUrlSessionCache(from: urlSession)
        return Self.gitHub(networkCache: sessionCache)
    }
    
    public static func macBookSteve() -> Self {
        let directory = URL(fileURLWithPath: "/Users/oleg/Development/TheGreatGame/Storage/content")
        let rawFS: Storage<APIPath, Data> = DiskFolderStorage(folderURL: directory, filenameEncoder: .noEncoding)
            .mapKeys({ Filename.init(rawValue: $0.rawValue) })
        let cache = rawFS
            .asReadOnlyStorage()
            .latency(ofInterval: 1.0)
        return Self(dataProvider: cache)
    }
    
    public static func makeUrlSessionCache(from session: URLSession = .init(configuration: .ephemeral)) -> ReadOnlyStorage<URL, Data> {
        return session
            .asReadOnlyStorage()
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
    
    public convenience init(dataProvider: ReadOnlyStorage<APIPath, Data>) {
        let teamsAPI = TeamsAPI.init(dataProvider: dataProvider)
        let matchesAPI = MatchesAPI.init(dataProvider: dataProvider)
        let groupsAPI = GroupsAPI.init(dataProvider: dataProvider)
        self.init(teams: teamsAPI, matches: matchesAPI, groups: groupsAPI)
    }
    
}

extension ReadOnlyStorage {
    
    public func latency(ofInterval interval: TimeInterval) -> ReadOnlyStorage<Key, Value> {
        return ReadOnlyStorage(storageName: self.storageName) { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: {
                    completion(result)
                })
            })
        }
    }
    
}

extension StorageProtocol {
    
    public func latency(ofInterval interval: TimeInterval) -> Storage<Key, Value> {
        return Storage(storageName: self.storageName, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: {
                    completion(result)
                })
            })
        }, set: { (value, key, completion) in
            self.set(value, forKey: key, completion: { (result) in
                DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: { 
                    completion(result)
                })
            })
        })
    }
    
}
