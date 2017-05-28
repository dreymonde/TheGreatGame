//
//  NetworkActivityIndicatorTests.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import XCTest
@testable import TheGreatKit

class NetworkActivityIndicatorTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testShowHide() {
        let expectation = self.expectation(description: "On hide")
        let manager = NetworkActivityIndicatorManager(show: { print("Showing") }, hide: expectation.fulfill)
        manager.increment()
        manager.increment()
        DispatchQueue.global().async {
            manager.decrement()
        }
        DispatchQueue.global().async {
            manager.decrement()
        }
        waitForExpectations(timeout: 5.0)
    }
    
}
