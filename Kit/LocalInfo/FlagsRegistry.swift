//
//  FlagsRegistry.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import Alba

public protocol RegistryDescriptor {
    
    associatedtype IDType : IDProtocol where IDType.RawValue == Int
    static var filename: Filename { get }
    
}

public enum FavoriteMatches : RegistryDescriptor {
    public typealias IDType = Match.ID
    public static var filename: Filename {
        return "matches"
    }
}

public enum FavoriteTeams : RegistryDescriptor {
    public typealias IDType = Team.ID
    public static var filename: Filename {
        return "teams"
    }
}

public enum UnsubscribedMatches : RegistryDescriptor {
    public typealias IDType = Match.ID
    public static var filename: Filename {
        return "unsubs"
    }
}

public final class FlagsRegistry<Descriptor : RegistryDescriptor> : SimpleStoring {
        
    public static func preferredDirectory(from base: BaseFolder.Type) -> Directory {
        let dir = base.Library.Application_Support.db.favorites
        print(dir.url)
        return dir
    }
    
    public static var filenameEncoder: Filename.Encoder {
        return .noEncoding
    }
    
    public typealias IDType = Descriptor.IDType
    
    fileprivate let full_flags: Storage<Void, Set<IDType>>
    
    public let flags: Retrieve<Set<IDType>>
    
    public var all: Set<IDType> {
        return try! flags.makeSyncStorage().retrieve()
    }
    
    private lazy var flagsSync: ReadOnlySyncStorage<Void, Set<IDType>> = self.flags.makeSyncStorage()
    
    public init(diskStorage: Disk) {
        let fileSystemTeams = diskStorage
            .renaming(to: "flags-disk")
            .mapJSONDictionary()
            .singleKey(Descriptor.filename)
            .mapBoxedSet(of: Descriptor.IDType.self)
            .defaulting(to: [])
        let memoryCache = MemoryStorage<Int, Set<IDType>>().singleKey(0)
        self.full_flags = memoryCache.combined(with: fileSystemTeams).serial()
        self.flags = full_flags.asReadOnlyStorage()
    }
    
    public struct Update {
        
        let changes: [Flags<Descriptor>.Change]
        let flags: Set<IDType>
        
        init(changes: [Flags<Descriptor>.Change], all: Set<IDType>) {
            self.changes = changes
            self.flags = all
        }
        
    }
    
    public let unitedDidUpdate = Publisher<Update>(label: "FlagsRegistry.unitedDidUpdate")
    
    public var didUpdatePresence: Subscribe<Flags<Descriptor>.Change> {
        return self.unitedDidUpdate.proxy.map({ $0.changes }).unfolded()
    }
    public var didUpdate: Subscribe<Set<IDType>> {
        return self.unitedDidUpdate.proxy.map({ $0.flags })
    }
    
    public func updatePresence(id: IDType, isPresent: Bool) {
        full_flags.update({ favs in
            if isPresent {
                favs.insert(id)
            } else {
                favs.remove(id)
            }
        }, completion: { result in
            if let new = result.value {
                let update = Flags<Descriptor>.Change(id: id, isPresent: isPresent)
                let united = Update(changes: [update], all: new)
                self.unitedDidUpdate.publish(united)
            }
        })
    }
    
    public func replace(with updated: Set<IDType>) {
        let existing = try! flagsSync.retrieve()
        let diff = existing.symmetricDifference(updated)
        full_flags.set(updated) { (result) in
            if result.isSuccess {
                let updates = diff.map({ Flags<Descriptor>.Change.init(id: $0, isPresent: updated.contains($0)) })
                let united = Update(changes: updates, all: updated)
                self.unitedDidUpdate.publish(united)
            }
        }
    }
    
    public func isPresent(id: IDType) -> Bool {
        do {
            let favs = try flagsSync.retrieve()
            return favs.contains(id)
        } catch {
            fault(error)
            return false
        }
    }
    
}

extension StorageProtocol where Value == [String : Any] {
    
    func mapBoxedSet<IDType : IDProtocol>(of type: IDType.Type = IDType.self) -> Storage<Key, Set<IDType>> where IDType.RawValue == Int {
        return self
            .mapMappable(of: FlagsBox<IDType>.self)
            .mapValues(transformIn: { Set($0.all) },
                       transformOut: { FlagsBox<IDType>(all: Array($0)) })
    }
    
}

internal struct FlagsBox<Value : IDProtocol> where Value.RawValue == Int {
    
    let all: [Value]
    
}

extension FlagsBox : Mappable {
    
    enum MappingKeys : String, IndexPathElement {
        case values
    }
    
    init<Source>(mapper: InMapper<Source, MappingKeys>) throws {
        self.all = try mapper.map(from: .values)
    }
    
    func outMap<Destination>(mapper: inout OutMapper<Destination, MappingKeys>) throws {
        try mapper.map(self.all, to: .values)
    }
    
}

