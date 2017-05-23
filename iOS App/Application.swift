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
    let cachier: APICachier
    let imageFetching: ImageFetch
    let favoriteTeams: FavoriteTeams
    
    init() {
        self.api = Application.makeAPI()
        self.imageFetching = ImageFetch(shouldCacheToDisk: true)
        self.cachier = Application.makeCachier()
        self.favoriteTeams = FavoriteTeams.inSharedDocumentsDirectory()
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
    
    static func makeCachier() -> APICachier {
        #if debug
            return APICachier.dev()
        #else
            return APICachier.inSharedCachesDirectory()
        #endif
//        let isCaching = launchArgument(.isCachingOnDisk)
//        return isCaching ? APICachier.inSharedDocumentsDirectory() : APICachier.dev()
    }
    
}
