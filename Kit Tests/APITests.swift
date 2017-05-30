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

class APITests: XCTestCase {
    
    static let testingNetworkCache: ReadOnlyCache<URL, Data> = URLSession(configuration: .ephemeral)
        .asReadOnlyCache()
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
        let api = TeamsAPI.gitHub(networkCache: APITests.testingNetworkCache)
        let teams = try api.all.mapValues({ $0.content.teams }).makeSyncCache().retrieve()
        XCTAssertEqual(teams.count, 16)
    }
    
    func testTeamID1() throws {
        let api = TeamsAPI.gitHub(networkCache: APITests.testingNetworkCache)
        let team1 = try api.fullTeam.mapValues({ $0.content }).makeSyncCache().retrieve(forKey: Team.ID(rawValue: 1)!)
        print(team1)
        XCTAssertEqual(team1.name, "Sweden")
        XCTAssertEqual(team1.shortName, "SWE")
        XCTAssertEqual(team1.id.rawID, 1)
        XCTAssertEqual(team1.group.teams.count, 4)
        XCTAssertEqual(team1.group.title, "Group B")
    }
    
    func testAllMatchesFull() throws {
        let api = MatchesAPI.macBookSteve()
        let matches = try api.allFull.mapValues({ $0.content.matches }).makeSyncCache().retrieve()
        let ned_nor = try matches.first.unwrap()
        let cut = ned_nor.snapshot(beforeMinute: 14)
        dump(cut)
        XCTAssertEqual(try cut.score.unwrap().home, 1)
    }
    
    func testStages() throws {
        let api = MatchesAPI.gitHub(networkCache: APITests.testingNetworkCache)
        let stages = try api.stages.mapValues({ $0.content }).makeSyncCache().retrieve()
    }
    
}
