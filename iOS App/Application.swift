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
    let apiCache: APICache
    let images: Images
    let favoriteTeams: Favorites<Team.ID>
    let tokens: DeviceTokens
    
    let watch: AppleWatch?
    let notifications: Notifications
    
    init() {
        Alba.InformBureau.isEnabled = true
        Alba.InformBureau.Logger.enable()

        self.api = Application.makeAPI()
        self.apiCache = Application.makeAPICache()
        self.images = Images.inSharedCachesDirectory()
        self.tokens = DeviceTokens()
        let favoriteConfig = Favorites<Team.ID>.Config(tokens: self.tokens, indicatorManager: .application)
        self.favoriteTeams = Favorites.inSharedDocumentsDirectory()(favoriteConfig)
        self.watch = AppleWatch()
        self.notifications = Notifications(application: UIApplication.shared)
        declare()
    }
    
    func declare() {
        tokens.declare(notifications: AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken.proxy,
                       complication: watch?.pushKitReceiver.didRegisterWithToken.proxy ?? .empty())
        watch?.declare(didUpdateFavorites: favoriteTeams.registry.didUpdateFavorites)
        favoriteTeams.declare()
    }
    
    static func makeAPI() -> API {
        let server = launchArgument(.server) ?? .heroku
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
    
    static func makeAPICache() -> APICache {
        let cachingDisabled = launchArgument(.isCachingDisabled)
        if cachingDisabled {
            return APICache.inMemory()
        } else {
            return APICache.inSharedCachesDirectory()
        }
    }
    
}
