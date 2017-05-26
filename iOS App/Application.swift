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
    let imageFetching: ImageFetch
    let favoriteTeams: FavoriteTeams
    let watch: AppleWatch
    let favoriteTeamsToWatch: FavoritesToAppleWatch
    
    init() {
        self.api = Application.makeAPI()
        self.apiCache = Application.makeAPICache()
        self.imageFetching = ImageFetch(shouldCacheToDisk: true)
        self.favoriteTeams = FavoriteTeams.inSharedDocumentsDirectory()
        self.watch = AppleWatch()
        self.favoriteTeamsToWatch = FavoritesToAppleWatch(watch: watch)
        favoriteTeamsToWatch.declare(favoritesDidUpdate: favoriteTeams.didUpdateFavorites.proxy)
    }
    
    static func makeAPI() -> API {
        let server = launchArgument(.server) ?? .github
        switch server {
        case .github:
            let urlSession = URLSession(configuration: .ephemeral)
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
            return APICache.dev()
        } else {
            return APICache.inSharedCachesDirectory()
        }
    }
    
}
