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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTeam1() {
        let access = GitHubRepoCache.init(owner: "dreymonde",
                                          repo: "TheGreatGameStorage",
                                          networkCache: URLSession.init(configuration: .ephemeral).makeReadOnly().droppingResponse().usingURLKeys())
        let expectation = self.expectation(description: "Expecting result")
        access.makeReadOnly()
            .mapJSONDictionary()
            .mapMappable(of: Editioned<TeamFull>.self)
            .retrieve(forKey: "teams/1.json") { (result) in
                print(result)
                expectation.fulfill()
        }
        waitForExpectations(timeout: 5.0)
    }
    
}
