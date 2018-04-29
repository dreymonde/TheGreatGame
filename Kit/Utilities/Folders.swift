//
//  DiskLayout.swift
//  TheGreatGame
//
//  Created by Олег on 19.01.2018.
//  Copyright © 2018 The Great Game. All rights reserved.
//

import Foundation

extension Library.Application_Support {
    
    public final class db : Directory { }
    
    public var db: db {
        return appending()
    }
    
    public final class Mirrors : Directory { }
    
    public var Mirrors: Mirrors {
        return appending()
    }
    
}

extension Library.Caches {
    
    public final class Images : Directory { }
    
    public var Images: Images {
        return appending()
    }
    
}

extension Library.Application_Support.db {
    
    public final class teams: Directory { }
    public final class stages: Directory { }
    public final class matches: Directory { }
    public final class groups: Directory { }
    
    public var teams: teams {
        return appending()
    }
    
    public var stages: stages {
        return appending()
    }
    
    public var matches: matches {
        return appending()
    }
    
    public var groups: groups {
        return appending()
    }
        
    public final class favorites: Directory { }
        
    public var favorites: favorites {
        return appending()
    }
    
}
