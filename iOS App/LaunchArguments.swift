//
//  LaunchArguments.swift
//  The Cleaning App
//
//  Created by Олег on 17.03.17.
//  Copyright © 2017 Two-212 Apps. All rights reserved.
//

import TheGreatKit

enum Server : String {
    case github
    case heroku
    case digitalOcean = "digital-ocean"
    case macBookSteve = "macbook-steve"
}

extension LaunchArgumentKey {
    
    static var isCachingDisabled: LaunchArgumentKey<Bool> {
        return LaunchArgumentKey<Bool>("disable-caching".bundled)
    }
    
    static var server: LaunchArgumentKey<Server> {
        return LaunchArgumentKey<Server>("server".bundled)
    }
    
}
