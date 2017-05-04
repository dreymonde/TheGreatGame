//
//  ShallowsExtensionsTests.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import XCTest
@testable import TheGreatKit
import Shallows

class ShallowsExtensionsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testZip() {
        let memCache1 = MemoryCache<Int, Int>(storage: [0: 15], name: "left").makeReadOnly()
        let memCache2 = MemoryCache<Int, String>(storage: [0: "Years"], name: "right").makeReadOnly()
        let expectation = self.expectation(description: "Waiting for zipped cache to complete")
        let zipped = zip(memCache1, memCache2).singleKey(0)
        zipped.retrieve { (result) in
            print(result)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)
    }
    
}
