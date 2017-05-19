//
//  TodayExtension.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import TheGreatKit

final class TodayExtension {
    
    let favoriteTeams: FavoriteTeams
    let api: API
    
    init() {
        self.api = API.gitHub(urlSession: .init(configuration: .default))
        self.favoriteTeams = FavoriteTeams.inSharedDocumentsDirectory()
    }
    
}
