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

public final class Favorites<IDType : IDProtocol> where IDType.RawValue == Int {
    
    public let registry: FavoritesRegistry<IDType>
    internal let uploader: FavoritesUploader<IDType>
    internal let uploadConsistencyKeeper: UploadConsistencyKeeper<Set<IDType>>
    
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
    
    internal init(registry: FavoritesRegistry<IDType>,
                  uploader: FavoritesUploader<IDType>,
                  uploadConsistencyKeeper: UploadConsistencyKeeper<Set<IDType>>,
                  shouldCheckUploadConsistency: Subscribe<Void>) {
        self.registry = registry
        self.uploader = uploader
        self.uploadConsistencyKeeper = uploadConsistencyKeeper
        
        start(shouldCheckUploadConsistency: shouldCheckUploadConsistency)
    }
        
    internal func start(shouldCheckUploadConsistency: Subscribe<Void>) {
        shouldCheckUploadConsistency.subscribe(uploadConsistencyKeeper, with: UploadConsistencyKeeper.check)
    }
    
    public func declare() {
        self.uploadConsistencyKeeper.declare(didUploadFavorites: uploader.didUploadFavorites.proxy.map({ $0.favorites }))
        self.uploader.declare(didUpdateFavorites: registry.unitedDidUpdate.proxy.map({ $0.favorites }))
    }
    
}

#if os(iOS)
    
    extension Favorites {
        
        public convenience init(favoritesRegistry: FavoritesRegistry<IDType>,
                                tokens: DeviceTokens,
                                shouldCheckUploadConsistency: Subscribe<Void>,
                                consistencyKeepersStorage: Cache<String, Data>,
                                upload: Cache<Void, Data>) {
            let favs = favoritesRegistry.favorites
            let uploader = FavoritesUploader<IDType>(pusher: FavoritesUploader.adapt(pusher: upload),
                                                     getNotificationsToken: tokens.getNotification,
                                                     getDeviceIdentifier: { UIDevice.current.identifierForVendor })
            let keeper = Favorites.makeKeeper(diskCache: consistencyKeepersStorage, favorites: favs, uploader: uploader)
            self.init(registry: favoritesRegistry,
                      uploader: uploader,
                      uploadConsistencyKeeper: keeper,
                      shouldCheckUploadConsistency: shouldCheckUploadConsistency)
        }
        
    }
    
    public func upload(forURL url: URL) -> Cache<String, Data> {
        return PUSHer(urlSession: URLSession.init(configuration: .default))
            .mapKeys({ url.appendingPathComponent($0) })
    }

    
#endif

extension Favorites {
    
    fileprivate static func makeKeeper(diskCache: Cache<String, Data>, favorites: Retrieve<Set<IDType>>, uploader: FavoritesUploader<IDType>) -> UploadConsistencyKeeper<Set<IDType>> {
        let name = "keeper-notifications-\(String(reflecting: IDType.self))"
        let last = diskCache
            .mapJSONDictionary()
            .mapBoxedSet(of: IDType.self)
            .singleKey(name)
            .defaulting(to: [])
        return UploadConsistencyKeeper<Set<IDType>>(actual: favorites, lastUploaded: last, name: name, reupload: { upload in
            uploader.uploadFavorites(upload)
        })
    }
    
}
