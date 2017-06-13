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
                  uploadConsistencyKeeper: UploadConsistencyKeeper<Set<IDType>>) {
        self.registry = registry
        self.uploader = uploader
        self.uploadConsistencyKeeper = uploadConsistencyKeeper
        
        start()
    }
        
    public func start() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            self.uploadConsistencyKeeper.check()
        }
    }
    
    public func declare() {
        self.uploadConsistencyKeeper.declare(didUploadFavorites: uploader.didUploadFavorites.proxy.map({ $0.favorites }))
        let keeperID = objectID(uploadConsistencyKeeper)
        let favors = self.registry.unitedDidUpdate.proxy.mapValue({ $0.favorites })
            .merged(with: uploadConsistencyKeeper.shouldUploadFavorites.proxy.signed(with: keeperID))
        self.uploader.declare(didUpdateFavorites: favors)
    }
    
}

extension Favorites : HardStoring {
    
    public struct Config {
        public let tokens: DeviceTokens
        public let indicatorManager: NetworkActivityIndicatorManager
        
        public init(tokens: DeviceTokens, indicatorManager: NetworkActivityIndicatorManager) {
            self.tokens = tokens
            self.indicatorManager = indicatorManager
        }
    }
    
    public typealias Configurable = (Config) -> Favorites
    
    public static var preferredSubPath: String {
        return "favorites"
    }
    
    public static func withDiskCache(_ diskCache: Cache<String, Data>) -> (Config) -> Favorites<IDType> {
        return { config in
            let registry = FavoritesRegistry<IDType>(diskCache: diskCache)
            
            let last = diskCache
                .mapJSONDictionary()
                .mapBoxedSet(of: IDType.self)
                .singleKey("keeped-uploads")
                .defaulting(to: [])
            let favs = registry.favoriteTeams
            
            let keeper = UploadConsistencyKeeper<Set<IDType>>(favorites: favs, lastUploaded: last)
            let uploader = FavoritesUploader<IDType>(pusher: PUSHer.init(urlSession: URLSession.init(configuration: .default)).singleKey(URL.init(string: "https://the-great-game-ruby.herokuapp.com/favorites")!).connectingNetworkActivityIndicator(manager: config.indicatorManager),
                                                     getNotificationsToken: { config.tokens.notifications.read() },
                                                     getComplicationToken: { config.tokens.complication.read() })
            return Favorites(registry: registry, uploader: uploader, uploadConsistencyKeeper: keeper)
        }
    }
    
}
