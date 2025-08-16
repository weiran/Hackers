//
//  HackersUITests.swift
//  HackersUITests
//
//  Created by Weiran Zhang on 23/03/2019.
//  Copyright © 2019 Weiran Zhang. All rights reserved.
//

import XCTest

class HackersUITests: XCTestCase {
//    let commentCellName = "OpenCommentCell"
//
//    func launch(darkTheme: Bool = false) {
//        let app = XCUIApplication()
//        setupSnapshot(app, waitForAnimations: false)
//        app.launchArguments = [
//            "disableReviewPrompts",
//            "skipAnimations",
//            "disableOnboarding"
//        ]
//
//        // set theme
//        if darkTheme {
//            app.launchArguments.append("darkMode")
//        }
//
//        app.launch()
//    }
//
//    func testScreenshotUltimate() {
//        launch()
//
//        let itemCell = XCUIApplication().collectionViews.cells.firstMatch
//        XCTAssertTrue(waitForElementToAppear(itemCell))
//
//        if Device.current.isPad {
//            itemCell.firstMatch.tap()
//
//            let commentsTable = XCUIApplication().tables["CommentsTableView"]
//            XCTAssertTrue(commentsTable.waitForExistence(timeout: 10))
//            XCTAssertTrue(waitForElementToAppear(commentsTable.cells[commentCellName]))
//            commentsTable.cells.allElementsBoundByIndex[1].tap()
//        }
//
//        snapshot("Ultimate")
//    }
//
//    func testScreenshotComments() {
//        launch()
//
//        let itemCell = XCUIApplication().collectionViews.cells.firstMatch
//        XCTAssertTrue(waitForElementToAppear(itemCell))
//        itemCell.firstMatch.tap()
//
//        let commentsTable = XCUIApplication().tables["CommentsTableView"]
//        XCTAssertTrue(commentsTable.waitForExistence(timeout: 10))
//        XCTAssertTrue(waitForElementToAppear(commentsTable.cells[commentCellName]))
//        commentsTable.cells.allElementsBoundByIndex[1].tap()
//
//        if !Device.current.isPad {
//            snapshot("Comments")
//        }
//    }
//
//    func testScreenshotDark() {
//        launch(darkTheme: true)
//
//        let itemCell = XCUIApplication().collectionViews.cells.firstMatch
//        XCTAssertTrue(waitForElementToAppear(itemCell))
//
//        if Device.current.isPad {
//            itemCell.firstMatch.tap()
//
//            let commentsTable = XCUIApplication().tables["CommentsTableView"]
//            XCTAssertTrue(commentsTable.waitForExistence(timeout: 10))
//            XCTAssertTrue(waitForElementToAppear(commentsTable.cells[commentCellName]))
//            commentsTable.cells.allElementsBoundByIndex[1].tap()
//        }
//
//        snapshot("Dark")
//    }
//
//    func waitForElementToAppear(_ element: XCUIElement) -> Bool {
//        let predicate = NSPredicate(format: "exists == true")
//        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
//        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
//        return result == .completed
//    }
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
