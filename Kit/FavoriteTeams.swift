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

fileprivate extension CacheProtocol {
    
    func defaulting(to defaultValue: Value) -> Cache<Key, Value> {
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
    
}

public final class FavoriteTeams {
    
    fileprivate let full_favoriteTeams: Cache<Void, Set<Team.ID>>
    private let fs: FileSystemCache
    
    public let favoriteTeams: ReadOnlyCache<Void, Set<Team.ID>>
    
    public init(fileSystemCache: FileSystemCache) {
        self.fs = fileSystemCache
        let fileSystemTeams = fileSystemCache
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
    
    public func updateFavorite(id: Team.ID, isFavorite: Bool) {
        full_favoriteTeams.update({ favs in
            if isFavorite {
                favs.insert(id)
            } else {
                favs.remove(id)
            }
        }, completion: { result in
            if result.isSuccess {
                self.didUpdateFavorite.publish((id, isFavorite: isFavorite))
            }
        })
    }
    
    public static func inDocumentsDirectory() -> FavoriteTeams {
        return FavoriteTeams(fileSystemCache: FileSystemCache.inDirectory(.documentDirectory, appending: "favorite-teams"))
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
