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
    
    init() {
        self.api = Application.makeAPI()
        self.imageFetching = ImageFetch(shouldCacheToDisk: true)
        self.cachier = Application.makeCachier()
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
        let isCaching = launchArgument(.isCachingOnDisk)
        return isCaching ? APICachier() : APICachier.dev()
    }
    
}
