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
        Loggers.start()
        
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
        declare()
    }
    
    func declare() {
        tokens.declare(notifications: AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken.proxy,
                       complication: watch?.pushKitReceiver.didRegisterWithToken.proxy ?? .empty())
        watch?.declare(didUpdateFavoriteTeams: favoriteTeams.registry.didUpdateFavorites,
                       didUpdateFavoriteMatches: favoriteMatches.registry.didUpdateFavorites)
        favoriteTeams.declare()
        favoriteMatches.declare()
        unsubscribedMatches.declare()
        let pushKitTokenConsistency = watch?.pushKitReceiver.didRegisterWithToken.proxy.void() ?? .empty()
        pushKitTokenUploader.declare(shouldCheckUploadConsistency: pushKitTokenConsistency)
    }
    
    static func makeAPI() -> API {
        let server = launchArgument(.server) ?? .github
        switch server {
        case .github:
            let urlSession = URLSession(configuration: .default)
            printWithContext("Using github as a server")
            return API.gitHub(urlSession: urlSession)
        case .macBookSteve:
            printWithContext("Using this MacBook as a server")
            return API.macBookSteve()
        case .heroku:
            printWithContext("Using the-great-game-ruby.herokuapp.com as a server (Heroku)")
            return API.heroku()
        }
    }
    
    static let shouldCheckUploadConsistency = AppDelegate.applicationDidBecomeActive.proxy
        .void()
        .wait(seconds: 4.0)
    
    static func makeFavorites(tokens: DeviceTokens) -> Favorites<Team.ID> {
        let keepersCache = FileSystemCache.inDirectory(.cachesDirectory, appending: "teams-upload-keepers")
        print(keepersCache.directoryURL)
        return Favorites<Team.ID>(favoritesRegistry: FavoritesRegistry.inSharedDocumentsDirectory(subpath: FavoriteTeamsSubPath),
                                  tokens: tokens,
                                  indicatorManager: .application,
                                  shouldCheckUploadConsistency: shouldCheckUploadConsistency,
                                  consistencyKeepersStorage: keepersCache.asCache(),
                                  apiSubpath: "favorite-teams")
    }
    
    static func makeFavorites(tokens: DeviceTokens) -> Favorites<Match.ID> {
        let keepersCache = FileSystemCache.inDirectory(.cachesDirectory, appending: "matches-upload-keepers")
        print(keepersCache.directoryURL)
        return Favorites<Match.ID>(favoritesRegistry: FavoritesRegistry.inSharedDocumentsDirectory(subpath: FavoriteMatchesSubPath),
                                   tokens: tokens,
                                   indicatorManager: .application,
                                   shouldCheckUploadConsistency: shouldCheckUploadConsistency,
                                   consistencyKeepersStorage: keepersCache.asCache(),
                                   apiSubpath: "favorite-matches")
    }

    static func makeUnsubscribes(tokens: DeviceTokens) -> Favorites<Match.ID> {
        let keepersCache = FileSystemCache.inDirectory(.cachesDirectory, appending: "matches-unsub-upload-keepers")
        return Favorites<Match.ID>(favoritesRegistry: FavoritesRegistry.inSharedDocumentsDirectory(subpath: UnsubscribedMatchesSubPath),
                                   tokens: tokens,
                                   indicatorManager: .application,
                                   shouldCheckUploadConsistency: shouldCheckUploadConsistency,
                                   consistencyKeepersStorage: keepersCache.asCache(),
                                   apiSubpath: "unsubscribe")
    }
    
    static func makeTokenUploader(getToken: Retrieve<PushToken>) -> TokenUploader {
        let fakeToken = PushToken(Data(repeating: 0, count: 1))
        
        let keeperesCache = FileSystemCache.inDirectory(.cachesDirectory, appending: "pushkit-token-upload-keeper")
            .mapValues(transformIn: PushToken.init,
                       transformOut: { $0.rawToken })
            .singleKey("uploaded-token")
            .defaulting(to: fakeToken)
        
        let fakeUpload = TokenUpload(deviceIdentifier: UIDevice.current.identifierForVendor!, token: fakeToken)
        return TokenUploader(pusher: DevCache.successing(with: fakeUpload),
                             getDeviceIdentifier: { UIDevice.current.identifierForVendor },
                             consistencyKeepersLastUpload: keeperesCache,
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
