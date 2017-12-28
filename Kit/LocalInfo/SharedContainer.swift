//
//  SharedContainer.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public protocol HardStoring {
    
    static var preferredSubPath: String { get }
    
    associatedtype Configurable
    
    static func withDiskCache(_ diskCache: Storage<Filename, Data>) -> Configurable
    
}

public protocol Storing : HardStoring {
    
    init(diskCache: Storage<Filename, Data>)
    
}

extension Storing {
    
    public static func withDiskCache(_ diskCache: Storage<Filename, Data>) -> Self {
        return Self.init(diskCache: diskCache)
    }
    
}

extension Filename : Hashable {
    
    public var hashValue: Int {
        return rawValue.hashValue
    }
    
}

extension HardStoring {
    
    public static func notStoring() -> Configurable {
        return Self.withDiskCache(.empty())
    }
    
    public static func inMemory() -> Configurable {
        return Self.withDiskCache(MemoryStorage<Filename, Data>().asStorage())
    }
    
    public static func inLocalCachesDirectory(subpath: String = Self.preferredSubPath) -> Configurable {
        return Self.withDiskCache(FileSystemStorage.inDirectory(.cachesDirectory,
                                                              appending: subpath).asStorage())
    }
    
    public static func inSharedCachesDirectory(subpath: String = Self.preferredSubPath) -> Configurable {
        return Self.withDiskCache(FileSystemStorage.inSharedContainer(subpath: FileSystemSubPath.caches(appending: subpath), qos: .default).asStorage())
    }
    
    public static func inLocalDocumentsDirectory(subpath: String = Self.preferredSubPath) -> Configurable {
        return Self.withDiskCache(FileSystemStorage.inDirectory(.documentDirectory, appending: subpath, qos: .userInitiated).asStorage())
    }
    
    public static func inSharedDocumentsDirectory(subpath: String = Self.preferredSubPath) -> Configurable {
        let diskCache = FileSystemStorage.inSharedContainer(subpath: .documents(appending: subpath), qos: .userInitiated)
        print(diskCache.directoryURL)
        return Self.withDiskCache(diskCache.asStorage())
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
        return FileSystemSubPath("Library/Caches/\(name)")
    }
    
    public static func documents(appending name: String) -> FileSystemSubPath {
        return FileSystemSubPath("Documents/\(name)")
    }
    
}

extension FileSystemStorageProtocol {
    
    public static func inSharedDocuments(folder: SubpathName) -> Self {
        let name = folder.fullStringValue
        return Self.inSharedContainer(subpath: .documents(appending: name), qos: .default)
    }
    
    public static func inSharedContainer(subpath: FileSystemSubPath, qos: DispatchQoS) -> Self {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TheGreatKit.groupIdentifier)?.appendingPathComponent(subpath.subpath)
        return Self.init(directoryURL: url!, qos: qos, storageName: "group-container")
    }
    
}
