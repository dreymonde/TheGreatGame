//
//  FavoritesTests.swift
//  TheGreatGame
//
//  Created by Олег on 19.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import XCTest
import Shallows
@testable import TheGreatKit

class FavoritesTests: XCTestCase {
    
    func testFavorites() throws {
        let fs = FileSystemCache.inDirectory(.cachesDirectory, appending: "fav-tests-1")
        let favs = FavoriteTeams(fileSystemCache: fs).favoriteTeams
        let sema = DispatchSemaphore(value: 0)
        favs.update({ $0.insert(Team.ID(rawValue: 1)!) }) { (result) in
            print(result)
            sema.signal()
        }
        sema.wait()
        let sync = favs.makeSyncCache()
        let withID1 = try sync.retrieve()
        XCTAssertEqual(withID1, [Team.ID.init(rawValue: 1)!])
        do { try FileManager.default.removeItem(at: fs.directoryURL) } catch {  }
    }
    
}
