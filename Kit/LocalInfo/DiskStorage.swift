//
//  SharedContainer.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

public struct DiskStorage : StorageProtocol {
    
    public enum BaseLocation {
        case localCaches
        case sharedCaches
        case localDocuments
        case sharedDocuments
    }
    
    public typealias Key = Filename
    public typealias Value = Data
    
    private let underlying: Storage<Filename, Data>
    
    public init(underlyingStorage: Storage<Filename, Data>) {
        self.underlying = underlyingStorage
    }
    
    public func retrieve(forKey key: Filename, completion: @escaping (Result<Data>) -> ()) {
        underlying.retrieve(forKey: key, completion: completion)
    }
    
    public func set(_ value: Data, forKey key: Filename, completion: @escaping (Result<Void>) -> ()) {
        underlying.set(value, forKey: key, completion: completion)
    }
    
    public init(baseFolder: BaseLocation, subfolder: SubpathName) {
        switch baseFolder {
        case .localCaches:
            self.init(underlyingStorage: FileSystemStorage.inDirectory(.cachesDirectory, appending: subfolder.fullStringValue).asStorage())
        case .localDocuments:
            self.init(underlyingStorage: FileSystemStorage.inDirectory(.documentDirectory, appending: subfolder.fullStringValue).asStorage())
        case .sharedCaches:
            self.init(underlyingStorage: FileSystemStorage.inSharedContainer(subpath: .caches(appending: subfolder.fullStringValue), qos: .default).asStorage())
        case .sharedDocuments:
            self.init(underlyingStorage: FileSystemStorage.inSharedContainer(subpath: .documents(appending: subfolder.fullStringValue), qos: .default).asStorage())
        }
    }
    
    public static func storage<StoringType : Storing>(for storingType: StoringType.Type, inBaseFolder baseFolder: BaseLocation) -> DiskStorage {
        return DiskStorage(baseFolder: baseFolder, subfolder: StoringType.preferredSubpath(from: FolderStructure.data))
    }
    
    public static func inLocalCaches(appending subpath: SubpathName) -> DiskStorage {
        return DiskStorage(baseFolder: .localCaches, subfolder: subpath)
    }
    
    public static func inSharedCaches(appending subpath: SubpathName) -> DiskStorage {
        return DiskStorage(baseFolder: .sharedCaches, subfolder: subpath)
    }
    
    public static func inLocalDocuments(appending subpath: SubpathName) -> DiskStorage {
        return DiskStorage(baseFolder: .localDocuments, subfolder: subpath)
    }
    
    public static func inSharedDocuments(appending subpath: SubpathName) -> DiskStorage {
        return DiskStorage(baseFolder: .sharedDocuments, subfolder: subpath)
    }
    
    public static func notStoring() -> DiskStorage {
        return DiskStorage(underlyingStorage: .empty())
    }
    
    public static func inMemory() -> DiskStorage {
        return DiskStorage(underlyingStorage: MemoryStorage().asStorage())
    }
    
}

public protocol Storing {
    
    static func preferredSubpath(from dataDir: data_dir) -> SubpathName
    
}

public protocol DBStoring : Storing {
    
    static func preferredSubpath(from dbDir: db_dir) -> SubpathName
    
}

extension DBStoring {
    
    public static func preferredSubpath(from dataDir: data_dir) -> SubpathName {
        return self.preferredSubpath(from: dataDir.db)
    }
    
}

public protocol SimpleStoring : Storing {
    
    init(diskStorage: DiskStorage)
    
}

extension SimpleStoring {
    
    public static func inLocation(_ baseLocation: DiskStorage.BaseLocation) -> Self {
        return Self.init(diskStorage: .storage(for: Self.self, inBaseFolder: baseLocation))
    }
    
}

extension Filename : Hashable {
    
    public var hashValue: Int {
        return rawValue.hashValue
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
