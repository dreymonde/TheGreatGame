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
        
    public func renaming(to newName: String) -> Cache<Key, Value> {
        return Cache(cacheName: newName, retrieve: self.retrieve, set: self.set)
    }
    
}

public final class FavoriteTeams : Storing {
    
    public static var preferredSubPath: String {
        return "favorite-teams"
    }
    
    fileprivate let full_favoriteTeams: Cache<Void, Set<Team.ID>>
    
    public let favoriteTeams: ReadOnlyCache<Void, Set<Team.ID>>
    
    public var all: Set<Team.ID> {
        return try! favoriteTeams.makeSyncCache().retrieve()
    }
    
    private lazy var favoriteTeamsSync: ReadOnlySyncCache<Void, Set<Team.ID>> = self.favoriteTeams.makeSyncCache()
    
    public init(diskCache: Cache<String, Data>) {
        let fileSystemTeams = diskCache
            .renaming(to: "favorites-disk")
            .mapJSONDictionary()
            .singleKey("favorite-teams")
            .mapMappable(of: Favorites.self)
            .mapValues(transformIn: { Set($0.teams) },
                       transformOut: { Favorites(teams: Array($0)) })
            .defaulting(to: [])
        let memoryCache = MemoryCache<Int, Set<Team.ID>>().singleKey(0)
        self.full_favoriteTeams = memoryCache.combined(with: fileSystemTeams).serial()
        self.favoriteTeams = full_favoriteTeams.asReadOnlyCache()
    }
    
    public struct Update {
        public var team: Team.ID
        public var isFavorite: Bool
        
        public init(teamID: Team.ID, isFavorite: Bool) {
            self.team = teamID
            self.isFavorite = isFavorite
        }
    }
    
    public let didUpdateFavorite = Publisher<Update>(label: "FavoriteTeams.didUpdateFavorite")
    public let didUpdateFavorites = Publisher<Set<Team.ID>>(label: "FavoriteTeams.didUpdateFavorites")
    
    public func updateFavorite(id: Team.ID, isFavorite: Bool) {
        full_favoriteTeams.update({ favs in
            if isFavorite {
                favs.insert(id)
            } else {
                favs.remove(id)
            }
        }, completion: { result in
            if let new = result.value {
                let update = Update(teamID: id, isFavorite: isFavorite)
                self.didUpdateFavorite.publish(update)
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
                    let update = Update(teamID: diffed, isFavorite: updated.contains(diffed))
                    self.didUpdateFavorite.publish(update)
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
