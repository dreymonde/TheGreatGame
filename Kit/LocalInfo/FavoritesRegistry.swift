//
//  FavoritesRegistry.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import Alba

public typealias FavoriteTeams = FavoritesRegistry<Team.ID>

public final class FavoritesRegistry<IDType : IDProtocol> : Storing where IDType.RawValue == Int {
    
    public static var preferredSubPath: String {
        return "favorite-teams"
    }
    
    fileprivate let full_favoriteTeams: Cache<Void, Set<IDType>>
    
    public let favoriteTeams: Retrieve<Set<IDType>>
    
    public var all: Set<IDType> {
        return try! favoriteTeams.makeSyncCache().retrieve()
    }
    
    private lazy var favoriteTeamsSync: ReadOnlySyncCache<Void, Set<IDType>> = self.favoriteTeams.makeSyncCache()
    
    public init(diskCache: Cache<String, Data>) {
        let fileSystemTeams = diskCache
            .renaming(to: "favorites-disk")
            .mapJSONDictionary()
            .singleKey("favorite-teams")
            .mapBoxedSet(of: IDType.self)
            .defaulting(to: [])
        let memoryCache = MemoryCache<Int, Set<IDType>>().singleKey(0)
        self.full_favoriteTeams = memoryCache.combined(with: fileSystemTeams).serial()
        self.favoriteTeams = full_favoriteTeams.asReadOnlyCache()
    }
    
    public struct Update {
        
        let changes: [Favorites<IDType>.Change]
        let favorites: Set<IDType>
        
        init(changes: [Favorites<IDType>.Change], all: Set<IDType>) {
            self.changes = changes
            self.favorites = all
        }
        
    }
    
    public let unitedDidUpdate = SignedPublisher<Update>(label: "FavoriteTeams.unitedDidUpdate")
    
    public var didUpdateFavorite: Subscribe<Favorites<IDType>.Change> {
        return self.unitedDidUpdate.proxy.unsigned.map({ $0.changes }).unfolded()
    }
    public var didUpdateFavorites: Subscribe<Set<IDType>> {
        return self.unitedDidUpdate.proxy.unsigned.map({ $0.favorites })
    }
    
    
    public func updateFavorite(id: IDType, isFavorite: Bool, submitter: ObjectIdentifier?) {
        full_favoriteTeams.update({ favs in
            if isFavorite {
                favs.insert(id)
            } else {
                favs.remove(id)
            }
        }, completion: { result in
            if let new = result.value {
                let update = Favorites.Change(id: id, isFavorite: isFavorite)
                let united = Update(changes: [update], all: new)
                self.unitedDidUpdate.publish(united, submitterIdentifier: submitter)
            }
        })
    }
    
    public func replace(with updated: Set<IDType>, submitter: ObjectIdentifier?) {
        let existing = try! favoriteTeamsSync.retrieve()
        let diff = existing.symmetricDifference(updated)
        full_favoriteTeams.set(updated) { (result) in
            if result.isSuccess {
                let updates = diff.map({ Favorites.Change.init(id: $0, isFavorite: updated.contains($0)) })
                let united = Update(changes: updates, all: updated)
                self.unitedDidUpdate.publish(united, submitterIdentifier: submitter)
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

extension CacheProtocol where Value == [String : Any] {
    
    func mapBoxedSet<IDType : IDProtocol>(of type: IDType.Type = IDType.self) -> Cache<Key, Set<IDType>> where IDType.RawValue == Int {
        return self
            .mapMappable(of: FavoritesBox<IDType>.self)
            .mapValues(transformIn: { Set($0.all) },
                       transformOut: { FavoritesBox<IDType>(all: Array($0)) })
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

