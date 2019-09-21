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
    func launch(darkTheme: Bool = false) {
        let app = XCUIApplication()
        setupSnapshot(app, waitForAnimations: false)
        app.launchArguments = [
            "-theme", darkTheme ? "dark" : "light",
            "disableReviewPrompts",
            "skipAnimations",
            "disableOnboarding"
        ]
        app.launch()
    }

    func testScreenshotUltimate() {
        launch()

        let tablesQuery = XCUIApplication().tables
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "PostCell").element))

        if Device.current.isPad {
            tablesQuery.cells.firstMatch.tap()
            let commentsTablesQuery = tablesQuery.cells.matching(identifier: "CommentCell")
            XCTAssertTrue(waitForElementToAppear(commentsTablesQuery.element))
            commentsTablesQuery.element(boundBy: 1).tap()
        }

        wait(for: 2)

        snapshot("Ultimate")
    }

    func testScreenshotComments() {
        if Device.current.isPad {
            return
        }

        launch()

        let tablesQuery = XCUIApplication().tables
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "PostCell").element))
        tablesQuery.cells.element(boundBy: 1).tap()

        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "CommentCell").element))
        tablesQuery.cells.element(boundBy: 1).tap()

        snapshot("Comments")
    }

    func testScreenshotDark() {
        launch(darkTheme: true)

        let tablesQuery = XCUIApplication().tables
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "PostCell").element))

        if Device.current.isPad {
            tablesQuery.cells.firstMatch.tap()
            let commentsTablesQuery = tablesQuery.cells.matching(identifier: "CommentCell")
            XCTAssertTrue(waitForElementToAppear(commentsTablesQuery.element))
            commentsTablesQuery.element(boundBy: 1).tap()
        }

        wait(for: 2)

        snapshot("Dark")
    }

    func waitForElementToAppear(_ element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        return result == .completed
    }
}

extension XCTestCase {
    func wait(for duration: TimeInterval) {
        let waitExpectation = expectation(description: "Waiting")

        let when = DispatchTime.now() + duration
        DispatchQueue.main.asyncAfter(deadline: when) {
            waitExpectation.fulfill()
        }

        waitForExpectations(timeout: duration)
    }
}
