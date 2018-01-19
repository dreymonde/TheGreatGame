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

public typealias FavoriteTeams = FavoritesRegistry<RD.Teams>

public protocol RegistryDescriptor {
    
    associatedtype IDType : IDProtocol where IDType.RawValue == Int
    static var filename: Filename { get }
    
}

public enum RD {
    
    public typealias Matches = MatchesRegistryDescriptor
    public typealias Teams = TeamsRegistryDescriptor
    public typealias Unsubs = UnsubsRegistryDescriptor
    
}

public enum MatchesRegistryDescriptor : RegistryDescriptor {
    public typealias IDType = Match.ID
    public static var filename: Filename {
        return "matches"
    }
}

public enum TeamsRegistryDescriptor : RegistryDescriptor {
    public typealias IDType = Team.ID
    public static var filename: Filename {
        return "teams"
    }
}

public enum UnsubsRegistryDescriptor : RegistryDescriptor {
    public typealias IDType = Match.ID
    public static var filename: Filename {
        return "unsubs"
    }
}

public final class FavoritesRegistry<Descriptor : RegistryDescriptor> : SimpleStoring {
        
    public static func preferredSubpath(from base: BaseFolder.Type) -> Directory {
        return base.Library.Application_Support.db.favorites
    }
    
    public typealias IDType = Descriptor.IDType
    
    fileprivate let full_favorites: Storage<Void, Set<IDType>>
    
    public let favorites: Retrieve<Set<IDType>>
    
    public var all: Set<IDType> {
        return try! favorites.makeSyncStorage().retrieve()
    }
    
    private lazy var favoriteTeamsSync: ReadOnlySyncStorage<Void, Set<IDType>> = self.favorites.makeSyncStorage()
    
    public init(diskStorage: Disk) {
        let fileSystemTeams = diskStorage
            .renaming(to: "favorites-disk")
            .mapJSONDictionary()
            .singleKey(Descriptor.filename)
            .mapBoxedSet(of: Descriptor.IDType.self)
            .defaulting(to: [])
        let memoryCache = MemoryStorage<Int, Set<IDType>>().singleKey(0)
        self.full_favorites = memoryCache.combined(with: fileSystemTeams).serial()
        self.favorites = full_favorites.asReadOnlyStorage()
    }
    
    public struct Update {
        
        let changes: [Favorites<Descriptor>.Change]
        let favorites: Set<IDType>
        
        init(changes: [Favorites<Descriptor>.Change], all: Set<IDType>) {
            self.changes = changes
            self.favorites = all
        }
        
    }
    
    public let unitedDidUpdate = Publisher<Update>(label: "FavoriteTeams.unitedDidUpdate")
    
    public var didUpdateFavorite: Subscribe<Favorites<Descriptor>.Change> {
        return self.unitedDidUpdate.proxy.map({ $0.changes }).unfolded()
    }
    public var didUpdateFavorites: Subscribe<Set<IDType>> {
        return self.unitedDidUpdate.proxy.map({ $0.favorites })
    }
    
    public func updateFavorite(id: IDType, isFavorite: Bool) {
        full_favorites.update({ favs in
            if isFavorite {
                favs.insert(id)
            } else {
                favs.remove(id)
            }
        }, completion: { result in
            if let new = result.value {
                let update = Favorites<Descriptor>.Change(id: id, isFavorite: isFavorite)
                let united = Update(changes: [update], all: new)
                self.unitedDidUpdate.publish(united)
            }
        })
    }
    
    public func replace(with updated: Set<IDType>) {
        let existing = try! favoriteTeamsSync.retrieve()
        let diff = existing.symmetricDifference(updated)
        full_favorites.set(updated) { (result) in
            if result.isSuccess {
                let updates = diff.map({ Favorites<Descriptor>.Change.init(id: $0, isFavorite: updated.contains($0)) })
                let united = Update(changes: updates, all: updated)
                self.unitedDidUpdate.publish(united)
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

extension StorageProtocol where Value == [String : Any] {
    
    func mapBoxedSet<IDType : IDProtocol>(of type: IDType.Type = IDType.self) -> Storage<Key, Set<IDType>> where IDType.RawValue == Int {
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
    
    init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.all = try mapper.map(from: .values)
    }
    
    func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.all, to: .values)
    }
    
}

