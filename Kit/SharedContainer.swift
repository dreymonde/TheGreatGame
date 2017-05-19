//
//  SharedContainer.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public let groupIdentifier = "group.com.the-great-game.the-great-group"

public struct FileSystemSubPath : ExpressibleByStringLiteral {
    
    public let subpath: String
    
    public init(stringLiteral value: String) {
        self.subpath = value
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.subpath = value
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.subpath = value
    }
    
    public init(_ subpath: String) {
        self.subpath = subpath
    }
    
    public static func caches(appending name: String) -> FileSystemSubPath {
        return FileSystemSubPath("Library/Caches/\(name)/")
    }
    
    public static func documents(appending name: String) -> FileSystemSubPath {
        return FileSystemSubPath("Documents/\(name)")
    }
    
}

extension FileSystemCacheProtocol {
    
    public static func inSharedContainer(appending subpath: FileSystemSubPath) -> Self {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TheGreatKit.groupIdentifier)?.appendingPathComponent(subpath.subpath)
        return Self.init(directoryURL: url!, cacheName: "group-container")
    }
    
}
