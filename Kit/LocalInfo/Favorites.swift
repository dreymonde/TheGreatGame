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

public func objectID(_ object: AnyObject) -> ObjectIdentifier {
    return ObjectIdentifier(object)
}

extension Subscribe where Event : Sequence {
    
    public func unfolded() -> Subscribe<Event.Iterator.Element> {
        return rawModify(subscribe: { (identifier, handler) in
            self.manual.subscribe(objectWith: identifier, with: { (sequence) in
                for element in sequence {
                    handler(element)
                }
            })
        }, entry: ProxyPayload.Entry.transformation(label: "unfolded", ProxyPayload.Entry.Transformation.transformed(fromType: Event.self, toType: Event.Iterator.self)))
    }
    
}

extension CacheProtocol {
        
    public func renaming(to newName: String) -> Cache<Key, Value> {
        return Cache(cacheName: newName, retrieve: self.retrieve, set: self.set)
    }
    
}

public final class Favorites<IDType : IDProtocol> where IDType.RawValue == Int {
    
    public let registry: FavoritesRegistry<IDType>
    internal let uploader: FavoritesUploader<IDType>
    
    public struct Change {
        public var id: IDType
        public var isFavorite: Bool
        
        public init(id: IDType, isFavorite: Bool) {
            self.id = id
            self.isFavorite = isFavorite
        }
        
        public var reversed: Change {
            return Change(id: id, isFavorite: !isFavorite)
        }
    }
    
    public init(tokens: DeviceTokens) {
        let registry = FavoritesRegistry<IDType>.inLocalDocumentsDirectory()
        self.registry = registry
        let uploader = FavoritesUploader<IDType>(getNotificationsToken: { tokens.notifications.read() }, getComplicationToken: { tokens.complication.read() })
        self.uploader = uploader
    }
    
    public func declare() {
//        self.uploader.declare(didUpdateFavorites: self.registry.didUpdateFavorite.proxy
//            .map({ ($0, self.registry.all) }))
        self.uploader.declare(didUpdateFavorites: self.registry.unitedDidUpdate.proxy)
    }
    
}

public typealias FavoriteTeams = FavoritesRegistry<Team.ID>

public final class FavoritesRegistry<IDType : IDProtocol> : Storing where IDType.RawValue == Int {
    
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
