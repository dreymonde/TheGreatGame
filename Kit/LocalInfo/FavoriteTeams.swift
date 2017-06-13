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

public typealias FavoriteTeams = Favorites<Team.ID>

public final class Favorites<IDType : IDProtocol> : Storing where IDType.RawValue == Int {
    
    public static var preferredSubPath: String {
        return "favorite-teams"
    }
    
    fileprivate let full_favoriteTeams: Cache<Void, Set<IDType>>
    
    public let favoriteTeams: ReadOnlyCache<Void, Set<IDType>>
    
    public var all: Set<IDType> {
        return try! favoriteTeams.makeSyncCache().retrieve()
    }
    
    private lazy var favoriteTeamsSync: ReadOnlySyncCache<Void, Set<IDType>> = self.favoriteTeams.makeSyncCache()
    
    public init(diskCache: Cache<String, Data>) {
        let fileSystemTeams = diskCache
            .renaming(to: "favorites-disk")
            .mapJSONDictionary()
            .singleKey("favorite-teams")
            .mapMappable(of: FavoritesBox<IDType>.self)
            .mapValues(transformIn: { Set($0.all) },
                       transformOut: { FavoritesBox(all: Array($0)) })
            .defaulting(to: [])
        let memoryCache = MemoryCache<Int, Set<IDType>>().singleKey(0)
        self.full_favoriteTeams = memoryCache.combined(with: fileSystemTeams).serial()
        self.favoriteTeams = full_favoriteTeams.asReadOnlyCache()
    }
    
    public struct Update {
        public var id: IDType
        public var isFavorite: Bool
        
        public init(id: IDType, isFavorite: Bool) {
            self.id = id
            self.isFavorite = isFavorite
        }
    }
    
    public let didUpdateFavorite = Publisher<Update>(label: "FavoriteTeams.didUpdateFavorite")
    public let didUpdateFavorites = Publisher<Set<IDType>>(label: "FavoriteTeams.didUpdateFavorites")
    
    public func updateFavorite(id: IDType, isFavorite: Bool) {
        full_favoriteTeams.update({ favs in
            if isFavorite {
                favs.insert(id)
            } else {
                favs.remove(id)
            }
        }, completion: { result in
            if let new = result.value {
                let update = Update(id: id, isFavorite: isFavorite)
                self.didUpdateFavorite.publish(update)
                self.didUpdateFavorites.publish(new)
            }
        })
    }
    
    public func replace(with updated: Set<IDType>) {
        let existing = try! favoriteTeamsSync.retrieve()
        let diff = existing.symmetricDifference(updated)
        full_favoriteTeams.set(updated) { (result) in
            if result.isSuccess {
                self.didUpdateFavorites.publish(updated)
                for diffed in diff {
                    let update = Update(id: diffed, isFavorite: updated.contains(diffed))
                    self.didUpdateFavorite.publish(update)
                }
            }
        }
    }
    
    public func isFavorite(id: IDType) -> Bool {
        do {
            let favs = try favoriteTeamsSync.retrieve()
            return favs.contains(id)
        } catch {
            fault(error)
            return false
        }
    }
        
}

internal struct FavoritesBox<Value : IDProtocol> where Value.RawValue == Int {
    
    let all: [Value]
    
}

extension FavoritesBox : Mappable {
    
    enum MappingKeys : String, IndexPathElement {
        case values
    }
    
    init<Source : InMap>(mapper: InMapper<Source, MappingKeys>) throws {
        self.all = try mapper.map(from: .values)
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.all, to: .values)
    }
    
}
