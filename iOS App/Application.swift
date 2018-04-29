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
        subscribe(onBehalfOf: favoriteTeams)
        subscribe(onBehalfOf: favoriteMatches)
        subscribe(onBehalfOf: unsubscribedMatches)
        let pushKitTokenConsistency = tokens.didUpdateComplicationToken.proxy.void()
        pushKitTokenUploader.subscribeTo(shouldCheckUploadConsistency: pushKitTokenConsistency)
    }
    
    private func subscribe<Flag>(onBehalfOf flags: Flags<Flag>) {
        flags.subscribeTo(shouldCheckUploadConsistency: Application.fourSecondsAfterAppDidBecomeActive)
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
            fatalError("DigitalOcean server is discontinued")
        }
    }
    
    static let fourSecondsAfterAppDidBecomeActive = AppDelegate.applicationDidBecomeActive.proxy
        .void()
        .wait(seconds: 4.0)
    
    static let uploadCache: WriteOnlyStorage<APIPath, Data> = makeUploader(forURL: Server.digitalOceanAPIBaseURL)
        .connectingNetworkActivityIndicator(indicator: .application)
    
    static func makeFlags<Flag : FlagDescriptor>(tokens: DeviceTokens, apiPath: APIPath) -> Flags<Flag> {
        return Flags<Flag>(registry: FlagsRegistry.inContainer(.shared),
                           tokens: tokens,
                           shouldCheckUploadConsistency: fourSecondsAfterAppDidBecomeActive,
                           upload: uploadCache.singleKey(apiPath))
    }
    
    static func makeFavorites(tokens: DeviceTokens) -> Flags<FavoriteTeams> {
        return makeFlags(tokens: tokens,
                        apiPath: "favorite-teams")
    }
    
    static func makeFavorites(tokens: DeviceTokens) -> Flags<FavoriteMatches> {
        return makeFlags(tokens: tokens,
                        apiPath: "favorite-matches")
    }
    
    static func makeUnsubscribes(tokens: DeviceTokens) -> Flags<UnsubscribedMatches> {
        return makeFlags(tokens: tokens,
                        apiPath: "unsubscribe")
    }
    
    static func makeTokenUploader(getToken: Retrieve<PushToken>) -> TokenUploader {
        let pusher = uploadCache.singleKey("pushkit-token")
        return TokenUploader(pusher: TokenUploader.adapt(pusher: pusher),
                             getDeviceIdentifier: { UIDevice.current.identifierForVendor },
                             serverMirror: TokenUploader.serverMirror(filename: "pushkit-token"),
                             getToken: getToken)
    }
    
    static func makeUploader(forURL url: URL) -> WriteOnlyStorage<APIPath, Data> {
        return .empty()
        //        return URLSessionPusher(urlSession: URLSession.init(configuration: .default))
        //            .asWriteOnlyStorage()
        //            .mapKeys({ url.appendingPath($0) })
    }
    
}
