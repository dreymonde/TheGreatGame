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
    internal let uploadConsistencyKeeper_notifications: UploadConsistencyKeeper<Set<IDType>>
    internal let uploadConsistencyKeeper_complication: UploadConsistencyKeeper<Set<IDType>>
    
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
                  uploadConsistencyKeeper_notifications: UploadConsistencyKeeper<Set<IDType>>,
                  uploadConsistencyKeeper_complication: UploadConsistencyKeeper<Set<IDType>>) {
        self.registry = registry
        self.uploader = uploader
        self.uploadConsistencyKeeper_notifications = uploadConsistencyKeeper_notifications
        self.uploadConsistencyKeeper_complication = uploadConsistencyKeeper_complication
        
        start()
    }
        
    public func start() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 3) {
            self.uploadConsistencyKeeper_notifications.check()
            self.uploadConsistencyKeeper_complication.check()
        }
    }
    
    public func declare() {
        self.uploadConsistencyKeeper_notifications.declare(didUploadFavorites: uploader.didUploadFavorites.proxy.filter({ $0.tokenType == TokenType.notifications }).map({ $0.favorites }))
        self.uploadConsistencyKeeper_complication.declare(didUploadFavorites: uploader.didUploadFavorites.proxy.filter({ $0.tokenType == TokenType.complication }).map({ $0.favorites }))
        self.uploader.declare(didUpdateFavorites: registry.unitedDidUpdate.proxy.mapValue({ $0.favorites }),
                              shouldUpdate_notifications: uploadConsistencyKeeper_notifications.shouldUploadFavorites.proxy,
                              shouldUpdate_complication: uploadConsistencyKeeper_complication.shouldUploadFavorites.proxy)
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
            let favs = registry.favoriteTeams
            let keeper_n = Favorites.makeKeeper(withName: "keeper-notifications", diskCache: diskCache, favorites: favs)
            let keeper_c = Favorites.makeKeeper(withName: "keeper-complications", diskCache: diskCache, favorites: favs)
            let uploader = FavoritesUploader<IDType>(pusher: PUSHer.init(urlSession: URLSession.init(configuration: .default)).singleKey(URL.init(string: "https://the-great-game-ruby.herokuapp.com/favorites")!).connectingNetworkActivityIndicator(manager: config.indicatorManager),
                                                     getNotificationsToken: config.tokens.getNotification,
                                                     getComplicationToken: config.tokens.getComplication)
            return Favorites(registry: registry,
                             uploader: uploader,
                             uploadConsistencyKeeper_notifications: keeper_n,
                             uploadConsistencyKeeper_complication: keeper_c)
        }
    }
    
    private static func makeKeeper(withName name: String, diskCache: Cache<String, Data>, favorites: Retrieve<Set<IDType>>) -> UploadConsistencyKeeper<Set<IDType>> {
        let last = diskCache
            .mapJSONDictionary()
            .mapBoxedSet(of: IDType.self)
            .singleKey(name)
            .defaulting(to: [])
        return UploadConsistencyKeeper<Set<IDType>>(favorites: favorites, lastUploaded: last)

    }
    
}
