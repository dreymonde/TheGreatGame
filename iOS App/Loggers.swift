//
//  Loggers.swift
//  TheGreatGame
//
//  Created by Олег on 15.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import TheGreatKit
import Shallows
import Alba

final class Loggers {
    
    static let cartographer: AlbaCartographer? = {
        #if DEBUG
            return AlbaCartographer(writeTo: URL(fileURLWithPath: "/Users/oleg/Desktop/tgg-graph.json", isDirectory: false))
        #else
            return nil
        #endif
    }()
    
    static func start() {
        Alba.InformBureau.isEnabled = true
        Alba.InformBureau.Logger.enable()
        #if DEBUG
            cartographer?.enable()
        #endif
    }
    
}
