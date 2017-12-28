//
//  DiskLayout.swift
//  TheGreatGame
//
//  Created by Олег on 26.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation

public class SubpathName {
    
    let previous: [SubpathName]
    
    var all: [SubpathName] {
        var a = previous
        a.append(self)
        return a
    }
    
    required public init(previous: [SubpathName] = []) {
        self.previous = previous
    }
    
    public final var singleStringValue: String {
        return String(String.init(describing: type(of: self)).split(separator: "_").first!)
    }
    
    public final var fullStringValue: String {
        return all.map({ $0.singleStringValue }).joined(separator: "/")
    }
    
    func adding<Name : SubpathName>(subpath: Name.Type = Name.self) -> Name {
        return Name(previous: all)
    }
    
}

public enum FolderStructure {
    
    public static var data: data_dir {
        return data_dir()
    }
    
}

public final class data_dir : SubpathName {
    
    public var db: db_dir {
        return adding()
    }
    
}

public final class db_dir : SubpathName {
    
    public var teams: teams_dir {
        return adding()
    }
    
    public var stages: stages_dir {
        return adding()
    }
    
    public var groups: groups_dir {
        return adding()
    }
    
    public var matches: matches_dir {
        return adding()
    }
    
}

public final class teams_dir : SubpathName { }
public final class stages_dir : SubpathName { }
public final class groups_dir : SubpathName { }
public final class matches_dir : SubpathName { }
