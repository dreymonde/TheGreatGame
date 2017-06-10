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
    let imageFetching: ImageFetch
    let favoriteTeams: FavoriteTeams
    let watch: AppleWatch?
    
    init() {
        Alba.InformBureau.isEnabled = true
        Alba.InformBureau.Logger.enable()

        self.api = Application.makeAPI()
        self.apiCache = Application.makeAPICache()
        self.imageFetching = ImageFetch.inSharedCachesDirectory()
        self.favoriteTeams = FavoriteTeams.inSharedDocumentsDirectory()
        self.watch = AppleWatch()
        declare()
    }
    
    func declare() {
        watch?.declare(didUpdateFavorites: favoriteTeams.didUpdateFavorites.proxy)
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
