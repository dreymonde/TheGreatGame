//
//  TeamsModel.swift
//  TheGreatGame
//
//  Created by Олег on 15.12.2017.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import Foundation
import Shallows
import Alba

public final class TeamsCompactModel {
    
    private let diskStorage: Storage<Filename, Data>
    private let teamsCompact: Storage<Void, [Team.Compact]>
    
    public init(diskStorage: Storage<Filename, Data>) {
        self.diskStorage = diskStorage
        self.teamsCompact = diskStorage
            .mapJSONDictionary()
            .mapMappable(of: [Team.Compact].self)
            .memoryCached()
            .singleKey("teams-compact-db")
    }
    
    public var access: Retrieve<[Team.Compact]> {
        return teamsCompact.asReadOnlyStorage()
    }
    
    public func update(with newValue: [Team.Compact]) {
        teamsCompact.set(newValue) { (result) in
            if result.isSuccess {
                self.didUpdate.publish(newValue)
            }
        }
    }
    
    public let didUpdate = Publisher<[Team.Compact]>(label: "TeamsCompactModel.didUpdate")
    
}

extension Storage where Key : Hashable {
    
    func memoryCached() -> Storage<Key, Value> {
        let memCache = MemoryStorage<Key, Value>()
        return memCache.combined(with: self)
    }
    
}
