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
                  uploadConsistencyKeeper_complication: UploadConsistencyKeeper<Set<IDType>>,
                  shouldCheckUploadConsistency: Subscribe<Void>) {
        self.registry = registry
        self.uploader = uploader
        self.uploadConsistencyKeeper_notifications = uploadConsistencyKeeper_notifications
        self.uploadConsistencyKeeper_complication = uploadConsistencyKeeper_complication
        
        start(shouldCheckUploadConsistency: shouldCheckUploadConsistency)
    }
        
    internal func start(shouldCheckUploadConsistency: Subscribe<Void>) {
        [uploadConsistencyKeeper_notifications, uploadConsistencyKeeper_complication].forEach { (keeper) in
            shouldCheckUploadConsistency.subscribe(keeper, with: UploadConsistencyKeeper.check)
        }
    }
    
    public func declare() {
        self.uploadConsistencyKeeper_notifications.declare(didUploadFavorites: uploader.didUploadFavorites.proxy.filter({ $0.tokenType == TokenType.notifications }).map({ $0.favorites }))
        self.uploadConsistencyKeeper_complication.declare(didUploadFavorites: uploader.didUploadFavorites.proxy.filter({ $0.tokenType == TokenType.complication }).map({ $0.favorites }))
        self.uploader.declare(didUpdateFavorites: registry.unitedDidUpdate.proxy.map({ $0.favorites }))
    }
    
}

extension Favorites {
    
    public convenience init(favoritesRegistry: FavoritesRegistry<IDType>, tokens: DeviceTokens, indicatorManager: NetworkActivityIndicatorManager, shouldCheckUploadConsistency: Subscribe<Void>, consistencyKeepersStorage: Cache<String, Data>, apiSubpath: String) {
        let favs = favoritesRegistry.favoriteTeams
        let uploader = FavoritesUploader<IDType>(pusher: PUSHer.init(urlSession: URLSession.init(configuration: .default)).singleKey(URL.init(string: "https://the-great-game-ruby.herokuapp.com/\(apiSubpath)")!).connectingNetworkActivityIndicator(manager: indicatorManager),
                                                 getNotificationsToken: tokens.getNotification,
                                                 getComplicationToken: tokens.getComplication)
        let keeper_n = Favorites.makeKeeper(witkTokenType: .notifications, diskCache: consistencyKeepersStorage, favorites: favs, uploader: uploader)
        let keeper_c = Favorites.makeKeeper(witkTokenType: .complication, diskCache: consistencyKeepersStorage, favorites: favs, uploader: uploader)
        self.init(registry: favoritesRegistry,
                  uploader: uploader,
                  uploadConsistencyKeeper_notifications: keeper_n,
                  uploadConsistencyKeeper_complication: keeper_c,
                  shouldCheckUploadConsistency: shouldCheckUploadConsistency)
    }
    
}

extension Favorites {
    
    fileprivate static func makeKeeper(witkTokenType tokenType: TokenType, diskCache: Cache<String, Data>, favorites: Retrieve<Set<IDType>>, uploader: FavoritesUploader<IDType>) -> UploadConsistencyKeeper<Set<IDType>> {
        
        let name = "keeper-\(tokenType)-\(String(reflecting: IDType.self))"
        let last = diskCache
            .mapJSONDictionary()
            .mapBoxedSet(of: IDType.self)
            .singleKey(name)
            .defaulting(to: [])
        return UploadConsistencyKeeper<Set<IDType>>(actual: favorites, lastUploaded: last, name: name, reupload: { upload in
            uploader.uploadFavorites(upload, tokenType: tokenType)
        })

    }
    
}
