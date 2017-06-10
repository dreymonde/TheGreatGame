//
//  APICacheTests.swift
//  TheGreatGame
//
//  Created by Олег on 23.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import XCTest
import Shallows
@testable import TheGreatKit

class APICacheTests: XCTestCase {
    
    func testSome() {
        let api = API.macBookSteve()
        let apiCache = APICache.inMemory()
        let matchesAPI = api.matches.stages
        let matchesAPICache = apiCache.matches.stages
        let combined = matchesAPICache.withSource(.disk).combinedRefreshing(with: matchesAPI.withSource(.server), isMoreRecent: { $0.value.isMoreRecent(than: $1.value) })
        combined.retrieve { (result) in
            dump(result.value?.source)
        }
        RunLoop.current.run()
    }
    
}
