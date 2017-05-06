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
    
    let teamsAPI: TeamsAPI
    let matchesAPI: MatchesAPI
    
    init() {
        let networkCache = URLSession(configuration: .ephemeral)
            .makeReadOnly()
            .droppingResponse()
            .usingURLKeys()
        self.teamsAPI = TeamsAPI(networkCache: networkCache)
        self.matchesAPI = MatchesAPI(networkCache: networkCache)
    }
    
}
