//
//  FavoriteTeams.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import Alba

extension CacheProtocol {
    
    public func defaulting(to defaultValue: Value) -> Cache<Key, Value> {
        return Cache(cacheName: self.cacheName, retrieve: { (key, completion) in
            self.retrieve(forKey: key, completion: { (result) in
                switch result {
                case .failure:
                    completion(.success(defaultValue))
                case .success(let value):
                    completion(.success(value))
                }
            })
        }, set: self.set)
    }
    
    public func renaming(to newName: String) -> Cache<Key, Value> {
        return Cache(cacheName: newName, retrieve: self.retrieve, set: self.set)
    }
    
}

public final class FavoriteTeams {
    
    fileprivate let full_favoriteTeams: Cache<Void, Set<Team.ID>>
    private let fs: FileSystemCache
    
    public let favoriteTeams: ReadOnlyCache<Void, Set<Team.ID>>
    
    private lazy var favoriteTeamsSync: ReadOnlySyncCache<Void, Set<Team.ID>> = self.favoriteTeams.makeSyncCache()
    
    public init(fileSystemCache: FileSystemCache) {
        self.fs = fileSystemCache
        let fileSystemTeams = fileSystemCache
            .renaming(to: "favorites-disk")
            .mapJSONDictionary()
            .singleKey("favorite-teams")
            .mapMappable(of: Favorites.self)
            .mapValues(transformIn: { Set($0.teams) },
                       transformOut: { Favorites(teams: Array($0)) })
            .defaulting(to: [])
        let memoryCache = MemoryCache<Int, Set<Team.ID>>().singleKey(0)
        self.full_favoriteTeams = memoryCache.combined(with: fileSystemTeams)
        self.favoriteTeams = full_favoriteTeams.asReadOnlyCache()
    }
    
    public let didUpdateFavorite = Publisher<(Team.ID, isFavorite: Bool)>(label: "FavoriteTeams.didUpdateFavorite")
    public let didUpdateFavorites = Publisher<Set<Team.ID>>(label: "FavoriteTeams.didUpdateFavorites")
    
    public func updateFavorite(id: Team.ID, isFavorite: Bool) {
        full_favoriteTeams.update({ favs in
            if isFavorite {
                favs.insert(id)
            } else {
                favs.remove(id)
            }
        }, completion: { result in
            if let new = result.asOptional {
                self.didUpdateFavorite.publish((id, isFavorite: isFavorite))
                self.didUpdateFavorites.publish(new)
            }
        })
    }
    
    public func replace(with updated: Set<Team.ID>) {
        let existing = try! favoriteTeamsSync.retrieve()
        let diff = existing.symmetricDifference(updated)
        full_favoriteTeams.set(updated) { (result) in
            if result.isSuccess {
                self.didUpdateFavorites.publish(updated)
                for diffed in diff {
                    self.didUpdateFavorite.publish((diffed, isFavorite: updated.contains(diffed)))
                }
            }
        }
    }
    
    public func isFavorite(teamWith id: Team.ID) -> Bool {
        do {
            let favs = try favoriteTeamsSync.retrieve()
            return favs.contains(id)
        } catch {
            fault(error)
            return false
        }
    }
    
    public static func inDocumentsDirectory() -> FavoriteTeams {
        return FavoriteTeams(fileSystemCache: FileSystemCache.inDirectory(.documentDirectory, appending: "favorite-teams"))
    }
    
    public static func inSharedDocumentsDirectory() -> FavoriteTeams {
        return FavoriteTeams(fileSystemCache: .inSharedContainer(subpath: .documents(appending: "favorite-teams"), qos: .userInitiated))
    }
    
}

internal struct Favorites {
    
    let teams: [Team.ID]
    
}

extension Favorites : Mappable {
    
    enum MappingKeys : String, IndexPathElement {
        case teams
    }
    
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.teams = try mapper.map(from: .teams)
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.teams, to: .teams)
    }
    
}
