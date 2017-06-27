//
//  Arguments.swift
//  TheGreatGame
//
//  Created by Олег on 27.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import TheGreatKit

extension LaunchArgumentKey {
    
    static var isCachingDisabled: LaunchArgumentKey<Bool> {
        return LaunchArgumentKey<Bool>("disable-caching".bundled)
    }
    
    static var server: LaunchArgumentKey<Server> {
        return LaunchArgumentKey<Server>("server".bundled)
    }
    
}
