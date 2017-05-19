//
//  ScoreViewModel.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import TheGreatKit

enum ScoreViewModel {
    
    case announcement(Date)
    case score(Match.Score)
    
}

extension Match.Score {
    
    var string: String {
        return "\(home):\(away)"
    }
    
}
