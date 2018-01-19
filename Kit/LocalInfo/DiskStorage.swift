//
//  SharedContainer.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows

extension DiskStorage {
    
    public func directory(_ directory: Directory,
                          filenameEncoder: Filename.Encoder = .base64) -> DiskFolderStorage {
        return DiskFolderStorage(folderURL: directory.url,
                                 diskStorage: self.asStorage(),
                                 filenameEncoder: filenameEncoder)
    }
    
}

public struct Disk : StorageProtocol {
    
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
    
    public init(directory: Directory) {
        self.init(underlyingStorage: DiskStorage.main.directory(directory).asStorage())
    }
    
    public static func storage<StoringType : Storing>(for storingType: StoringType.Type, baseFolder: BaseFolder.Type) -> Disk {
        return Disk(directory: StoringType.preferredSubpath(from: baseFolder))
    }
    
//    public static func inLocalCaches(appending directory: Directory) -> Disk {
//        return Disk(baseFolder: .localCaches, subfolder: subpath)
//    }
//
//    public static func inSharedCaches(appending subpath: SubpathName) -> Disk {
//        return Disk(baseFolder: .sharedCaches, subfolder: subpath)
//    }
//
//    public static func inLocalDocuments(appending subpath: SubpathName) -> Disk {
//        return Disk(baseFolder: .localDocuments, subfolder: subpath)
//    }
//
//    public static func inSharedDocuments(appending subpath: SubpathName) -> Disk {
//        return Disk(baseFolder: .sharedDocuments, subfolder: subpath)
//    }
    
    public static func notStoring() -> Disk {
        return Disk(underlyingStorage: .empty())
    }
    
    public static func inMemory() -> Disk {
        return Disk(underlyingStorage: MemoryStorage().asStorage())
    }
    
}

public protocol Storing {
    
    static func preferredSubpath(from base: BaseFolder.Type) -> Directory
    
}

public protocol DBStoring : Storing {
    
    static func preferredSubpath(from db: Library.Application_Support.db) -> Directory
    
}

extension DBStoring {
    
    public static func preferredSubpath(from base: BaseFolder.Type) -> Directory {
        return self.preferredSubpath(from: base.Library.Application_Support.db)
    }
    
}

public protocol SimpleStoring : Storing {
    
    init(diskStorage: Disk)
    
}

public enum Container {
    case appFolder
    case shared
    
    public var baseFolder: BaseFolder.Type {
        switch self {
        case .appFolder:
            return AppFolder.self
        case .shared:
            return AppGroupContainer<TheGreatGroup>.self
        }
    }
}

extension SimpleStoring {
    
    public static func inContainer(_ container: Container) -> Self {
        return Self.init(diskStorage: .storage(for: Self.self, baseFolder: container.baseFolder))
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

public enum TheGreatGroup : AppGroup {
    public static var groupIdentifier: String {
        return TheGreatKit.groupIdentifier
    }
}

public typealias SharedContainer = AppGroupContainer<TheGreatGroup>

extension FileSystemStorageProtocol {
    
//    public static func inSharedDocuments(folder: SubpathName) -> Self {
//        let name = folder.fullStringValue
//        return Self.inSharedContainer(subpath: .documents(appending: name), qos: .default)
//    }
//
//    public static func inSharedContainer(subpath: FileSystemSubPath, qos: DispatchQoS) -> Self {
//        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: TheGreatKit.groupIdentifier)?.appendingPathComponent(subpath.subpath)
//        printWithContext(url!.description)
//        return Self.init(directoryURL: url!, qos: qos, storageName: "group-container")
//    }
    
}
