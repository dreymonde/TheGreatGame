//
//  SharedContainer.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public protocol Storing {
    
    static var preferredSubPath: String { get }
    
    init(diskCache: Cache<String, Data>)
    
}

extension Storing {
    
    public static func notStoring() -> Self {
        return Self.init(diskCache: .empty())
    }
    
    public static func inMemory() -> Self {
        return Self.init(diskCache: MemoryCache<String, Data>().asCache())
    }
    
    public static func inLocalCachesDirectory(subpath: String = Self.preferredSubPath) -> Self {
        return Self.init(diskCache: FileSystemCache.inDirectory(.cachesDirectory,
                                                                appending: subpath).asCache())
    }
    
    public static func inSharedCachesDirectory(subpath: String = Self.preferredSubPath) -> Self {
        return Self.init(diskCache: FileSystemCache.inSharedContainer(subpath: FileSystemSubPath.caches(appending: subpath), qos: .default).asCache())
    }
    
    public static func inLocalDocumentsDirectory(subpath: String = Self.preferredSubPath) -> Self {
        return Self.init(diskCache: FileSystemCache.inDirectory(.documentDirectory, appending: subpath, qos: .userInitiated).asCache())
    }
    
    public static func inSharedDocumentsDirectory(subpath: String = Self.preferredSubPath) -> Self {
        return Self.init(diskCache: FileSystemCache.inSharedContainer(subpath: .documents(appending: subpath), qos: .userInitiated).asCache())
    }

    
}

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
    
    public static func inSharedContainer(subpath: FileSystemSubPath, qos: DispatchQoS) -> Self {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TheGreatKit.groupIdentifier)?.appendingPathComponent(subpath.subpath)
        return Self.init(directoryURL: url!, qos: qos, cacheName: "group-container")
    }
    
}
