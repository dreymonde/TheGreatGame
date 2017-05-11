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
        let urlSession = URLSession(configuration: .ephemeral)
        self.api = API.gitHub(urlSession: urlSession)
        self.imageFetching = ImageFetch(shouldCacheToDisk: true)
        self.cachier = APICachier()
    }
    
}
