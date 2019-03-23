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

    override func setUp() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments = ["-Theme", "light"]
        app.launch()
    }

    func screenshotUltimate() {
        let tablesQuery = XCUIApplication().tables
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "PostCell").element))
        
        if self.device.isPad {
            tablesQuery.cells.firstMatch.tap()
            XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "CommentCell").element))
            tablesQuery.cells.element(boundBy: 1).tap()
        }
        
        snapshot("Ultimate")
    }
    
    func screenshotComments() {
        if self.device.isPad {
            return
        }
        
        let tablesQuery = XCUIApplication().tables
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "PostCell").element))
        tablesQuery.cells.firstMatch.tap()
        
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "CommentCell").element))
        tablesQuery.cells.element(boundBy: 1).tap()
        
        snapshot("Comments")
    }
    
    func waitForElementToAppear(_ element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        return result == .completed
    }
}
