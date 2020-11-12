//
//  HackersUITests.swift
//  HackersUITests
//
//  Created by Weiran Zhang on 23/03/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import XCTest
import DeviceKit

class HackersUITests: XCTestCase {
    func launch(darkTheme: Bool = false) {
        let app = XCUIApplication()
        setupSnapshot(app, waitForAnimations: false)
        app.launchArguments = [
            "disableReviewPrompts",
            "skipAnimations",
            "disableOnboarding"
        ]

        // set theme
        app.launchArguments.append("-systemTheme")
        app.launchArguments.append("false")
        app.launchArguments.append("-theme")
        if darkTheme {
            app.launchArguments.append("dark")
        } else {
            app.launchArguments.append("light")
        }

        app.launch()
    }

    func testScreenshotUltimate() {
        launch()

        let tablesQuery = XCUIApplication().tables
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "PostCell").element))

        if Device.current.isPad {
            tablesQuery.cells.firstMatch.tap()
            XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "CommentCell").element))
        }

        snapshot("Ultimate")
    }

    func testScreenshotComments() {
        launch()

        let tablesQuery = XCUIApplication().tables
        let postCell = tablesQuery.cells.matching(identifier: "PostCell").element
        XCTAssertTrue(waitForElementToAppear(postCell))
        postCell.firstMatch.tap()

        let commentCell = tablesQuery.cells.matching(identifier: "CommentCell").element
        XCTAssertTrue(waitForElementToAppear(commentCell))

        if !Device.current.isPad {
            snapshot("Comments")
        }
    }

    func testScreenshotDark() {
        launch(darkTheme: true)

        let tablesQuery = XCUIApplication().tables
        XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "PostCell").element))

        if Device.current.isPad {
            tablesQuery.cells.firstMatch.tap()
            XCTAssertTrue(waitForElementToAppear(tablesQuery.cells.matching(identifier: "CommentCell").element))
        }

        snapshot("Dark")
    }

    func waitForElementToAppear(_ element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 60)
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
