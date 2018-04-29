//
//  UploadTests.swift
//  TheGreatGame
//
//  Created by Oleg Dreyman on 13.06.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import XCTest
import Shallows
import Alba
@testable import TheGreatKit

class EventTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAdditionalEventFE() {
        let event = Match.Event(kind: .halftime_start, text: "FE test", realMinute: 115, matchMinute: 90)
        XCTAssertEqual(event.kind, .end_and_extra)
        XCTAssertEqual(event.text, "test")
    }
    
    func testAdditionalEventET() {
        let event = Match.Event(kind: .halftime_end, text: "ET test", realMinute: 115, matchMinute: 90)
        XCTAssertEqual(event.kind, .extra_start)
        XCTAssertEqual(event.text, "test")
    }
    
}
