//
//  ComplicationDataSourceTests.swift
//  TheGreatGame
//
//  Created by Олег on 28.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import XCTest
import Shallows
@testable import TheGreatKit

class ComplicationDataSourceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAfter() throws {
        let api = API.gitHub()
        let allMatches = api.matches.allFull.mapValues({ $0.content.matches }).makeSyncCache()
        let dateComps = DateComponents(calendar: nil, timeZone: TimeZone.init(identifier: "Europe/Amsterdam"), era: nil, year: 2017, month: 7, day: 21, hour: 21, minute: 0, second: 0, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        let date = try Calendar.current.date(from: dateComps).unwrap()
        let all = try allMatches.retrieve().snapshots()
        dump(all.after(date))
        print("DEEEEEEE")
        dump(all.before(date))
    }
    
}
