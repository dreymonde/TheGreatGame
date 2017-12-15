//
//  Application.swift
//  TheGreatGame
//
//  Created by Олег on 03.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import TheGreatKit
import Shallows

final class Application {
    
    let api: API
    let apiCache: APICache
    let images: Images
    let favoriteTeams: Favorites<Team.ID>
    let favoriteMatches: Favorites<Match.ID>
    let unsubscribedMatches: Favorites<Match.ID>
    let tokens: DeviceTokens
    let pushKitTokenUploader: TokenUploader
    
    let watch: AppleWatch?
    let notifications: Notifications
    
    init() {
        //Loggers.start()
        
        self.api = Application.makeAPI()
        self.apiCache = Application.makeAPICache()
        self.images = Images.inSharedCachesDirectory()
        self.tokens = DeviceTokens()
        self.favoriteTeams = Application.makeFavorites(tokens: tokens)
        self.favoriteMatches = Application.makeFavorites(tokens: tokens)
        self.unsubscribedMatches = Application.makeUnsubscribes(tokens: tokens)
        self.pushKitTokenUploader = Application.makeTokenUploader(getToken: tokens.getComplication)
        self.watch = AppleWatch(favoriteTeams: favoriteTeams.registry.favorites,
                                favoriteMatches: favoriteMatches.registry.favorites)
        self.notifications = Notifications(application: UIApplication.shared)
        subscribe()
    }
    
    func subscribe() {
        tokens.subscribeTo(notifications: AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken.proxy,
                       complication: watch?.pushKitReceiver.didRegisterWithToken.proxy ?? .empty())
        watch?.subscribeTo(didUpdateFavoriteTeams: favoriteTeams.registry.didUpdateFavorites,
                       didUpdateFavoriteMatches: favoriteMatches.registry.didUpdateFavorites)
        favoriteTeams.subscribe()
        favoriteMatches.subscribe()
        unsubscribedMatches.subscribe()
        let pushKitTokenConsistency = tokens.didUpdateComplicationToken.proxy.void()
        pushKitTokenUploader.subscribeTo(shouldCheckUploadConsistency: pushKitTokenConsistency)
    }
    
    static func makeAPI() -> API {
        let server = Server.production
        switch server {
        case .github:
            printWithContext("Using github as a server")
            return API.gitHub()
        case .githubRaw:
            printWithContext("Using github raw file system as a server")
            return API.gitHubRaw()
        case .macBookSteve:
            printWithContext("Using this MacBook as a server")
            return API.macBookSteve()
        case .heroku:
            printWithContext("Using the-great-game-ruby.herokuapp.com as a server (Heroku)")
            return API.heroku()
        case .digitalOcean:
            printWithContext("Using Digital Ocean droplet as a content server")
            return API.digitalOcean()
        }
    }
    
    static let shouldCheckUploadConsistency = AppDelegate.applicationDidBecomeActive.proxy
        .void()
        .wait(seconds: 4.0)
    
    static let uploadCache = upload(forURL: Server.digitalOceanAPIBaseURL)
        .connectingNetworkActivityIndicator(manager: .application)
    
    static func makeFavorites(tokens: DeviceTokens) -> Favorites<Team.ID> {
        let keepersCache = FileSystemStorage.inDirectory(.cachesDirectory, appending: "teams-upload-keepers")
        print(keepersCache.directoryURL)
        return Favorites<Team.ID>(favoritesRegistry: FavoritesRegistry.inSharedDocumentsDirectory(subpath: FavoriteTeamsSubPath),
                                  tokens: tokens,
                                  shouldCheckUploadConsistency: shouldCheckUploadConsistency,
                                  consistencyKeepersStorage: keepersCache.asStorage(),
                                  upload: uploadCache.singleKey("favorite-teams"))
    }
    
    static func makeFavorites(tokens: DeviceTokens) -> Favorites<Match.ID> {
        let keepersCache = FileSystemStorage.inDirectory(.cachesDirectory, appending: "matches-upload-keepers")
        print(keepersCache.directoryURL)
        return Favorites<Match.ID>(favoritesRegistry: FavoritesRegistry.inSharedDocumentsDirectory(subpath: FavoriteMatchesSubPath),
                                   tokens: tokens,
                                   shouldCheckUploadConsistency: shouldCheckUploadConsistency,
                                   consistencyKeepersStorage: keepersCache.asStorage(),
                                   upload: uploadCache.singleKey("favorite-matches"))
    }

    static func makeUnsubscribes(tokens: DeviceTokens) -> Favorites<Match.ID> {
        let keepersCache = FileSystemStorage.inDirectory(.cachesDirectory, appending: "matches-unsub-upload-keepers")
        return Favorites<Match.ID>(favoritesRegistry: FavoritesRegistry.inSharedDocumentsDirectory(subpath: UnsubscribedMatchesSubPath),
                                   tokens: tokens,
                                   shouldCheckUploadConsistency: shouldCheckUploadConsistency,
                                   consistencyKeepersStorage: keepersCache.asStorage(),
                                   upload: uploadCache.singleKey("unsubscribe"))
    }
    
    static func makeTokenUploader(getToken: Retrieve<PushToken>) -> TokenUploader {
        let fakeToken = PushToken(Data(repeating: 0, count: 1))
        
        let keepersCache = FileSystemStorage.inDirectory(.cachesDirectory, appending: "pushkit-token-upload-keeper")
            .mapValues(transformIn: PushToken.init,
                       transformOut: { $0.rawToken })
            .singleKey("uploaded-token")
            .defaulting(to: fakeToken)
        
        let pusher = uploadCache.singleKey("pushkit-token")
        
        return TokenUploader(pusher: TokenUploader.adapt(pusher: pusher),
                             getDeviceIdentifier: { UIDevice.current.identifierForVendor },
                             consistencyKeepersLastUpload: keepersCache,
                             getToken: getToken)
    }
    
    static func makeAPICache() -> APICache {
        let cachingDisabled = launchArgument(.isCachingDisabled)
        if cachingDisabled {
            return APICache.inMemory()
        } else {
            return APICache.inSharedCachesDirectory()
        }
    }
    
}
