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

public protocol FlagDescriptor {
    
    associatedtype IDType : IDProtocol where IDType.RawValue == Int
    static var filename: Filename { get }
    
}

public enum FavoriteMatches : FlagDescriptor {
    public typealias IDType = Match.ID
    public static var filename: Filename {
        return "matches"
    }
}

extension FlagDescriptor {
    
    public typealias Set = FlagSet<Self>
    
}

public enum FavoriteTeams : FlagDescriptor {
    public typealias IDType = Team.ID
    public static var filename: Filename {
        return "teams"
    }
}

public enum UnsubscribedMatches : FlagDescriptor {
    public typealias IDType = Match.ID
    public static var filename: Filename {
        return "unsubs"
    }
}

public struct FlagSet<Flag : FlagDescriptor> : Equatable {
    
    public var set: Set<Flag.IDType>
    
    public init(_ set: Set<Flag.IDType>) {
        self.set = set
    }
    
}

public final class FlagsRegistry<Flag : FlagDescriptor> : SimpleStoring {
        
    public static func preferredDirectory(from base: BaseFolder.Type) -> Directory {
        let dir = base.Library.Application_Support.db.favorites
        return dir
    }
    
    public static var filenameEncoder: Filename.Encoder {
        return .noEncoding
    }
    
    public typealias IDType = Flag.IDType
    
    fileprivate let memoryCachedFlags: MemoryCached<FlagSet<Flag>>
    
    public let flags: Retrieve<FlagSet<Flag>>
    
    public var all: FlagSet<Flag> {
        return memoryCachedFlags.read()
    }
    
    public init(diskStorage: Disk) {
        let fileSystemFlags = diskStorage
            .renaming(to: "flags-disk")
            .mapJSONDictionary()
            .singleKey(Flag.filename)
            .mapFlagSet(of: Flag.self)
        self.memoryCachedFlags = MemoryCached(io: fileSystemFlags, defaultValue: FlagSet([]))
        self.flags = memoryCachedFlags.ioRead
    }
    
    public struct Update {
        
        let changes: [Flags<Flag>.Change]
        let flags: FlagSet<Flag>
        
        init(changes: [Flags<Flag>.Change], all: FlagSet<Flag>) {
            self.changes = changes
            self.flags = all
        }
        
    }
    
    public let unitedDidUpdate = Publisher<Update>(label: "FlagsRegistry<\(Flag.self)>.unitedDidUpdate")
    
    public var didUpdatePresence: Subscribe<Flags<Flag>.Change> {
        return self.unitedDidUpdate.proxy.map({ $0.changes }).unfolded()
    }
    public var didUpdate: Subscribe<FlagSet<Flag>> {
        return self.unitedDidUpdate.proxy.map({ $0.flags })
    }
    
    public func updatePresence(id: IDType, isPresent: Bool) {
        memoryCachedFlags.write { (flags) in
            if isPresent {
                flags.set.insert(id)
            } else {
                flags.set.remove(id)
            }
        }
        let update = Flags<Flag>.Change(id: id, isPresent: isPresent)
        let united = Update(changes: [update], all: memoryCachedFlags.read())
        unitedDidUpdate.publish(united)
    }
    
    public func replace(with updated: FlagSet<Flag>) {
        let existing = memoryCachedFlags.read()
        let diff = existing.set.symmetricDifference(updated.set)
        memoryCachedFlags.write(updated)
        let updates = diff.map({ Flags<Flag>.Change.init(id: $0, isPresent: updated.set.contains($0)) })
        let united = Update(changes: updates, all: updated)
        self.unitedDidUpdate.publish(united)
    }
    
    public func forceRefreshMemoryCache() {
        memoryCachedFlags.forceRefresh()
    }
    
    public func isPresent(id: IDType) -> Bool {
        return memoryCachedFlags.read().set.contains(id)
    }
    
}

extension StorageProtocol where Value == [String : Any] {
    
    func mapBoxedSet<IDType : IDProtocol>(of type: IDType.Type = IDType.self) -> Storage<Key, Set<IDType>> where IDType.RawValue == Int {
        return self
            .mapMappable(of: FlagsBox<IDType>.self)
            .mapValues(transformIn: { Set($0.all) },
                       transformOut: { FlagsBox<IDType>(all: Array($0)) })
    }
    
    func mapFlagSet<Flag : FlagDescriptor>(of type: Flag.Type = Flag.self) -> Storage<Key, FlagSet<Flag>> {
        return self
            .mapBoxedSet(of: Flag.IDType.self)
            .mapValues(to: FlagSet<Flag>.self,
                       transformIn: FlagSet.init,
                       transformOut: { $0.set })
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

public final class MemoryCached<Value> {
    
    private let underlying: Storage<Void, Value>
    public var ioRead: ReadOnlyStorage<Void, Value> {
        return underlying.asReadOnlyStorage()
    }
    
    private var inMemory: Value
    
    init(io: Storage<Void, Value>, defaultValue: Value) {
        self.underlying = io
        do {
            self.inMemory = try io.makeSyncStorage().retrieve()
        } catch {
            self.inMemory = defaultValue
        }
    }
    
    public func forceRefresh() {
        do {
            self.inMemory = try underlying.makeSyncStorage().retrieve()
        } catch {
            fault(error)
        }
    }
    
    public func readIO() -> Value? {
        return try? ioRead.makeSyncStorage().retrieve()
    }
    
    public func read() -> Value {
        return inMemory
    }
    
    public func write(_ newValue: Value) {
        inMemory = newValue
        push(inMemory)
    }
    
    private func push(_ updatedValue: Value) {
        underlying.set(updatedValue) { result in
            if let error = result.error {
                fault("FlagsRegistry MemoryCached error:")
                fault(error)
            }
        }
    }
    
    public func write(with block: (inout Value) -> ()) {
        block(&inMemory)
        push(inMemory)
    }
    
}
