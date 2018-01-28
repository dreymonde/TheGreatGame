//
//  FavoritesTests.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import XCTest
import Shallows
import Alba
@testable import TheGreatKit

class Waiter<Event> {
    
    let queue = DispatchQueue(label: "alba-waiter")
    let sema = DispatchSemaphore(value: 0)
    
    let times: Int
    var events: [Event] = []
    
    init(times: Int) {
        self.times = times
    }
    
    func append(event: Event) {
        queue.async {
            self.events.append(event)
            if self.events.count == self.times {
                self.sema.signal()
            }
        }
    }
    
    @discardableResult
    func wait() -> Event {
        return waitMany().first!
    }
    
    @discardableResult
    func waitMany() -> [Event] {
        sema.wait()
        return events
    }
    
}

extension Subscribe {
    
    func makeWaiter(times: Int = 1) -> Waiter<Event> {
        let waiter = Waiter<Event>(times: times)
        self.subscribe(waiter, with: Waiter.append)
        return waiter
    }
    
}

class FavoritesTests: XCTestCase {
    
    func testFavorites() throws {
        let fs = DiskStorage.main.folder("fav-tests-1", in: .cachesDirectory)
        let favs = FlagsRegistry<FavoriteTeams>(diskStorage: Disk(underlyingStorage: fs.asStorage()))
        let waiter = favs.didUpdatePresence.makeWaiter()
        favs.updatePresence(id: Team.ID(rawValue: 1)!, isPresent: true)
        waiter.wait()
        let sync = favs.flags.makeSyncStorage()
        let withID1 = try sync.retrieve()
        XCTAssertEqual(withID1, [Team.ID.init(rawValue: 1)!])
        do { try FileManager.default.removeItem(at: fs.folderURL) } catch {  }
    }
    
    func testGetMatches() throws {
        let fs = DiskStorage.main.folder("fav-tests-2", in: .cachesDirectory)
        let favs = FlagsRegistry<FavoriteTeams>(diskStorage: Disk(underlyingStorage: fs.asStorage()))
        let waiter = favs.didUpdatePresence.makeWaiter()
        favs.updatePresence(id: Team.ID(rawValue: 1)!, isPresent: true)
        waiter.wait()
        let favsIDs = try favs.flags.makeSyncStorage().retrieve()
        let api = API.digitalOcean().matches.all.mapValues({ $0.content.matches }).makeSyncStorage()
        let matches = try api.retrieve().filter({ favsIDs.contains($0.home.id) || favsIDs.contains($0.away.id) })
        dump(matches.mostRelevant()!)
        do { try FileManager.default.removeItem(at: fs.folderURL) } catch {  }
    }
    
}
