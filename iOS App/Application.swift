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
import Alba

final class Application {
    
    let api: API
    let localDB: LocalDB
    let connections: Connections
    let images: Images
    let favoriteTeams: Flags<FavoriteTeams>
    let favoriteMatches: Flags<FavoriteMatches>
    let unsubscribedMatches: Flags<UnsubscribedMatches>
    let tokens: DeviceTokens
    let pushKitTokenUploader: TokenUploader
    
    let watch: AppleWatch?
    let notifications: Notifications
    
    init() {
        Loggers.start()
        self.api = Application.makeAPI()
        self.localDB = LocalDB.inContainer(.shared)
        self.connections = Connections(api: api, localDB: localDB, activityIndicator: .application)
        self.images = Images.inContainer(.shared)
        self.tokens = DeviceTokens()
        self.favoriteTeams = Application.makeFavorites(tokens: tokens)
        self.favoriteMatches = Application.makeFavorites(tokens: tokens)
        self.unsubscribedMatches = Application.makeUnsubscribes(tokens: tokens)
        self.pushKitTokenUploader = Application.makeTokenUploader(getToken: tokens.getComplication)
        self.watch = AppleWatch(favoriteTeams: favoriteTeams.registry.flags,
                                favoriteMatches: favoriteMatches.registry.flags)
        self.notifications = Notifications(application: UIApplication.shared)
        subscribe()
    }
    
    func subscribe() {
        tokens.subscribeTo(notifications: AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken.proxy,
                           complication: watch?.pushKitReceiver.didRegisterWithToken.proxy ?? .empty())
        watch?.subscribeTo(didUpdateFavoriteTeams: favoriteTeams.registry.didUpdate,
                           didUpdateFavoriteMatches: favoriteMatches.registry.didUpdate)
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
            return API.gitHubDirectLimited()
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
    
    static let fourSecondAfterAppDidBecomeActive = AppDelegate.applicationDidBecomeActive.proxy
        .void()
        .wait(seconds: 4.0)
    
    static let uploadCache: WriteOnlyStorage<APIPath, Data> = makeUploader(forURL: Server.digitalOceanAPIBaseURL)
        .connectingNetworkActivityIndicator(indicator: .application)
    
    static func makeFavs<Flag : FlagDescriptor>(tokens: DeviceTokens,
                                                          keeperFolderName: String,
                                                          apiPath: APIPath) -> Flags<Flag> {
        let keepersCache = DiskStorage.main.folder(keeperFolderName, in: .cachesDirectory)
        return Flags<Flag>(registry: FlagsRegistry.inContainer(.shared),
                                 tokens: tokens,
                                 shouldCheckUploadConsistency: fourSecondAfterAppDidBecomeActive,
                                 consistencyKeepersStorage: keepersCache.asStorage(),
                                 upload: uploadCache.singleKey(apiPath))
    }
    
    static func makeFavorites(tokens: DeviceTokens) -> Flags<FavoriteTeams> {
        return makeFavs(tokens: tokens,
                        keeperFolderName: "teams-upload-keepers",
                        apiPath: "favorite-teams")
    }
    
    static func makeFavorites(tokens: DeviceTokens) -> Flags<FavoriteMatches> {
        return makeFavs(tokens: tokens,
                        keeperFolderName: "matches-upload-keepers",
                        apiPath: "favorite-matches")
    }
    
    static func makeUnsubscribes(tokens: DeviceTokens) -> Flags<UnsubscribedMatches> {
        return makeFavs(tokens: tokens,
                        keeperFolderName: "matches-unsub-upload-keepers",
                        apiPath: "unsubscribe")
    }
    
    static func makeTokenUploader(getToken: Retrieve<PushToken>) -> TokenUploader {
        let fakeToken = PushToken(Data(repeating: 0, count: 1))
        
        let keepersCache = DiskStorage.main.folder("pushkit-token-upload-keeper", in: .cachesDirectory)
            .mapValues(transformIn: PushToken.init,
                       transformOut: { $0.rawToken })
            .singleKey("uploaded-token")
            .defaulting(to: fakeToken)
        
        let pusher = uploadCache.singleKey("pushkit-token")
        
        return TokenUploader(pusher: TokenUploader.adapt(pusher: pusher),
                             getDeviceIdentifier: { UIDevice.current.identifierForVendor },
                             consistencyKeepersStorage: keepersCache,
                             getToken: getToken)
    }
    
    static func makeUploader(forURL url: URL) -> WriteOnlyStorage<APIPath, Data> {
        return .empty()
//        return URLSessionPusher(urlSession: URLSession.init(configuration: .default))
//            .asWriteOnlyStorage()
//            .mapKeys({ url.appendingPath($0) })
    }
    
}
