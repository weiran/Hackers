import XCTest
import DeviceKit

class DanilUITests: XCTestCase {
    let commentCellName = "OpenCommentCell"

    func launch(darkTheme: Bool = false) {
        let app = XCUIApplication()
        setupSnapshot(app, waitForAnimations: false)
        app.launchArguments = [
            "disableReviewPrompts",
            "skipAnimations",
            "disableOnboarding"
        ]

        app.launch()
    }




    // FIXME: не работает
    func testCheckOpenSettingsScreen() {
        launch()

        let itemCell = XCUIApplication().collectionViews.cells.firstMatch
        let setting = XCUIApplication().navigationBars.buttons["Settings"]
        setting.tap()
        XCTAssertTrue(XCUIApplication().staticTexts["Hackers, By Weiran Zhang"].exists)
    }


    func testOpenSecondPostAndCheckFirstComment() {
        launch()

        let itemCell = XCUIApplication().collectionViews.cells.element(boundBy: 1)
        XCTAssertTrue(waitForElementToAppear(itemCell))
        itemCell.firstMatch.tap()

        let commentsTable = XCUIApplication().tables["CommentsTableView"]
        XCTAssertTrue(commentsTable.waitForExistence(timeout: 10))
        XCTAssertTrue(commentsTable.cells.allElementsBoundByIndex[0].exists)
    }

    
    // FIXME: не работает
    func testTypeLoginAndPasswordFields() {
        let app = XCUIApplication()
        setupSnapshot(app, waitForAnimations: false)
        app.launchArguments = [
            "disableReviewPrompts",
            "skipAnimations",
            "disableOnboarding"
        ]

        app.launch()

        let itemCell = XCUIApplication().collectionViews.cells.firstMatch
        let setting = XCUIApplication().navigationBars.buttons["Settings"]
        setting.tap()

        let loginButton = XCUIApplication().tables.cells.staticTexts["Account"]
        print(loginButton)
        loginButton.tap()
        let loginButton2 = XCUIApplication().buttons["l2"]
        let loginButton3 = XCUIApplication().buttons["l3"]
        XCTAssertTrue(false)
    }


    func testOpenSpecificNamePost() {
        launch()

        var findPost = false
        let expectedPostName = "Build Your Own Redis with C/C++"
        XCTAssertTrue(XCUIApplication().collectionViews.cells.firstMatch.waitForExistence(timeout: 10))
        let countCells = XCUIApplication().collectionViews.cells.count
        for ind in 0...countCells {
            let currentPostName = XCUIApplication().collectionViews.cells.element(boundBy: ind).staticTexts.element(boundBy: 0).label
            print(currentPostName)
            if currentPostName == expectedPostName {
                XCUIApplication().collectionViews.cells.element(boundBy: ind).tap()
                findPost = true
                break
            }
        }
        XCTAssertTrue(findPost, "Post not found")
    }

    func testCheckExistPostWithImageStub() {
        let app = XCUIApplication()
        setupSnapshot(app, waitForAnimations: false)
        app.launchArguments = [
            "disableReviewPrompts",
            "skipAnimations",
            "disableOnboarding"
        ]

        app.launch()

        var findStub = false
        let expectedPostName = "Build Your Own"
        XCTAssertTrue(XCUIApplication().collectionViews.cells.firstMatch.waitForExistence(timeout: 10))
        let countCells = XCUIApplication().collectionViews.cells.count
        for ind in 0...countCells {
            let currentPostName = XCUIApplication().collectionViews.cells.element(boundBy: ind).images["safari"]
            if currentPostName.exists {
                print("Stub in post №  \(ind + 1)")
                findStub = true
                break
            }
        }
        XCTAssertTrue(findStub, "Stub not found")
    }



    func waitForElementToAppear(_ element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        return result == .completed
    }
}
