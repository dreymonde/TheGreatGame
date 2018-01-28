//
//  TheGreatGameUITests.swift
//  TheGreatGameUITests
//
//  Created by Олег on 28.01.2018.
//  Copyright © 2018 The Great Game. All rights reserved.
//

import XCTest

class TheGreatGameUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    func testNorway() {
        
        let app = XCUIApplication()
        app.tables.staticTexts["Norway"].tap()
        let screenshot = app.tables.cells.element(boundBy: 0).screenshot()
        let attachment = XCTAttachment(image: screenshot.image)
        attachment.lifetime = .keepAlways
        add(attachment)
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
