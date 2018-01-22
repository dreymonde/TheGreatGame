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
    
    public init(directory: Directory, filenameEncoder: Filename.Encoder = .base64) {
        self.init(underlyingStorage: DiskStorage.main.directory(directory, filenameEncoder: filenameEncoder).asStorage())
    }
    
    public static func notStoring() -> Disk {
        return Disk(underlyingStorage: .empty())
    }
    
    public static func inMemory() -> Disk {
        return Disk(underlyingStorage: MemoryStorage().asStorage())
    }
    
}

public protocol DeepStoring {
    
    associatedtype PreferredDirectory : Directory
    
    static func preferredDirectory(from base: BaseFolder.Type) -> PreferredDirectory
    static var filenameEncoder: Filename.Encoder { get }
    
}

public protocol Storing : DeepStoring {
    
    static func preferredDirectory(from base: BaseFolder.Type) -> Directory
    
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

extension DeepStoring {
    
    public static func substorage(
        in container: Container,
        topFolder: (BaseFolder.Type) -> PreferredDirectory = Self.preferredDirectory,
        subFolder: (PreferredDirectory) -> Directory,
        filenameEncoder: Filename.Encoder = Self.filenameEncoder
    ) -> Disk {
        return Disk(directory: subFolder(topFolder(container.baseFolder)), filenameEncoder: filenameEncoder)
    }
    
}

extension Storing {
    
    public static func storage(in container: Container,
                               folder: (BaseFolder.Type) -> Directory = Self.preferredDirectory,
                               filenameEncoder: Filename.Encoder = Self.filenameEncoder) -> Disk {
        return Disk(directory: folder(container.baseFolder), filenameEncoder: filenameEncoder)
    }
    
}

extension SimpleStoring {
    
    public static func inContainer(_ container: Container,
                                   folder: (BaseFolder.Type) -> Directory = Self.preferredDirectory,
                                   filenameEncoder: Filename.Encoder = Self.filenameEncoder) -> Self {
        return Self.init(diskStorage: storage(in: container, folder: folder, filenameEncoder: filenameEncoder))
    }
    
}

public let groupIdentifier = "group.com.the-great-game.the-great-group"

public enum TheGreatGroup : AppGroup {
    public static var groupIdentifier: String {
        return TheGreatKit.groupIdentifier
    }
}

public typealias SharedContainer = AppGroupContainer<TheGreatGroup>
