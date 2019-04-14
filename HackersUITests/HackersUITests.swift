//
//  HackersUITests.swift
//  HackersUITests
//
//  Created by Weiran Zhang on 23/03/2019.
//  Copyright © 2019 Glass Umbrella. All rights reserved.
//

import XCTest
import DeviceKit

class HackersUITests: XCTestCase {
    let device = Device()
    
    func launch(darkTheme: Bool = false) {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments = ["-Theme", darkTheme ? "dark" : "light"]
        app.launch()
    }

    func testScreenshotUltimate() {
        launch()
        
        let tablesQuery = XCUIApplication().tables
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "PostCell").element))
        
        if self.device.isPad {
            tablesQuery.cells.firstMatch.tap()
            XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "CommentCell").element))
            tablesQuery.cells.element(boundBy: 1).tap()
        }
        
        snapshot("Ultimate")
    }
    
    func testScreenshotComments() {
        if self.device.isPad {
            return
        }
        
        launch()
        
        let tablesQuery = XCUIApplication().tables
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "PostCell").element))
        tablesQuery.cells.firstMatch.tap()
        
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "CommentCell").element))
        tablesQuery.cells.element(boundBy: 1).tap()
        
        snapshot("Comments")
    }
    
    func testScreenshotDark() {
        launch(darkTheme: true)
        
        let tablesQuery = XCUIApplication().tables
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "PostCell").element))
        
        if self.device.isPad {
            tablesQuery.cells.firstMatch.tap()
            XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "CommentCell").element))
            tablesQuery.cells.element(boundBy: 1).tap()
        }
        
        snapshot("Dark")
    }
    
    func waitForElementToAppear(_ element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        return result == .completed
    }
}
