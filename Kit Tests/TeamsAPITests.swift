//
//  TeamsAPITests.swift
//  TheGreatGame
//
//  Created by Олег on 04.05.17.
//  Copyright © 2017 The Great Game. All rights reserved.
//

import XCTest
import Shallows
@testable import TheGreatKit

class TeamsAPITests: XCTestCase {
    
    static let testingNetworkCache: ReadOnlyCache<URL, Data> = URLSession(configuration: .ephemeral)
        .makeReadOnly()
        .droppingResponse()
        .usingURLKeys()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAllTeams() throws {
        let api = TeamsAPI(networkCache: TeamsAPITests.testingNetworkCache)
        let teams = try api.all.mapValues({ $0.content.teams }).makeSyncCache().retrieve()
        XCTAssertEqual(teams.count, 16)
    }
    
    func testTeamID1() throws {
        let api = TeamsAPI(networkCache: TeamsAPITests.testingNetworkCache)
        let team1 = try api.fullTeam.mapValues({ $0.content }).makeSyncCache().retrieve(forKey: Team.ID(rawValue: 1)!)
        print(team1)
        XCTAssertEqual(team1.name, "Sweden")
        XCTAssertEqual(team1.shortName, "SWE")
        XCTAssertEqual(team1.id.rawID, 1)
        XCTAssertEqual(team1.group.teams.count, 4)
        XCTAssertEqual(team1.group.title, "Group B")
    }
    
}
