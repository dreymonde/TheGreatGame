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

//filepriipublic enum FolderStructure {
//
//    public static var data: data_dir {
//        return data_dir()
//    }
//
//}
//
//public final class data_dir : SubpathName {
//
//    public var db: db_dir {
//        return adding()
//    }
//
//    public var images: images_dir {
//        return adding()
//    }
//
//}
//
//public final class images_dir : SubpathName { }
//
//public final class db_dir : SubpathName {
//
//    public var teams: teams_dir {
//        return adding()
//    }
//
//    public var stages: stages_dir {
//        return adding()
//    }
//
//    public var groups: groups_dir {
//        return adding()
//    }
//
//    public var matches: matches_dir {
//        return adding()
//    }
//
//    public var favorites: favorites_dir {
//        return adding()
//    }
//
//}
//
//public final class favorites_dir : SubpathName {
//
//    //    public var teams: teams_dir {
//    //        return adding()
//    //    }
//    //
//    //    public var matches: matches_dir {
//    //        return adding()
//    //    }
//    //
//    //    public var unsubs: unsubs_dir {
//    //        return adding()
//    //    }
//
//}
//
//public final class unsubs_dir : SubpathName { }
//public final class teams_dir : SubpathName { }
//public final class stages_dir : SubpathName { }
//public final class groups_dir : SubpathName { }
//public final class matches_dir : SubpathName { }

