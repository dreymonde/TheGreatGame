//
//  LaunchArguments.swift
//  The Cleaning App
//
//  Created by Олег on 17.03.17.
//  Copyright © 2017 Two-212 Apps. All rights reserved.
//

import Foundation

public enum Server : String {
    case github
    case heroku
    case digitalOcean = "digital-ocean"
    case macBookSteve = "macbook-steve"
    
    public static let digitalOceanStorageBaseURL = URL(string: "https://storage.thegreatgame.world/content")!
    public static let digitalOceanAPIBaseURL = URL(string: "https://storage.thegreatgame.world")!
    
}
