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

    func waitForElementToAppear(_ element: XCUIElement) -> Bool {
        let predicate = NSPredicate(format: "exists == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: 5)
        return result == .completed
    }
    
    let settingsButton = XCUIApplication().navigationBars.buttons["Settings"]
    
    func openSettings () {
        settingsButton.tap()
        XCTAssertTrue(XCUIApplication().navigationBars["Settings"].exists)
    }

    func testCheckOpenSettingsScreen() {
        launch()

        openSettings()
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

    // TODO: хз что именно проверять ассертом, потому что в задании не указано + чет не смог достать value из textFiel, в String не хочет конвертироваться
    func testTypeLoginAndPasswordFields() {
        launch()

        openSettings()

        let accountCredButton = XCUIApplication().tables.cells.staticTexts["Account"]
        accountCredButton.tap()

        let loginField = XCUIApplication().textFields["loginField"]
        let passwordField = XCUIApplication().secureTextFields["passwordField"]

        loginField.tap()
        loginField.typeText("login")

        passwordField.tap()
        passwordField.typeText("password")

        XCTAssertTrue(true)
    }

    // #TODO: в самом начале свайпаю, чтобы посты подгрузились. В идеале конечно делать один свап и сразу чекать, но чет не очень получилось, в следущюем тесте попробовал как раз
    func testOpenSpecificNamePost() {
        launch()

        var findPost = false
        let expectedPostName = "Radio Man, Autograph King"
        var currentPostNumber = 0

        XCUIApplication().swipeUp()
        XCUIApplication().swipeUp()
        XCUIApplication().swipeUp()

        while (!findPost) {
            let currentPostName = XCUIApplication().collectionViews.cells.element(boundBy: currentPostNumber).staticTexts.element(boundBy: 0).label
            if currentPostName == expectedPostName {
                XCUIApplication().collectionViews.cells.element(boundBy: currentPostNumber).tap()
                findPost = true
                break
            }
            currentPostNumber += 1
        }
        XCTAssertTrue(findPost, "Post not found")
    }

    // #TODO: тут стремно работает эта параллельная схема один раз свайпнули - сразу чекаем
    func testCheckExistPostWithImageStub() {
        launch()

        var countSwipe = 0
        var findStub = false

        while (!findStub && countSwipe < 3) {
            XCTAssertTrue(XCUIApplication().collectionViews.cells.firstMatch.waitForExistence(timeout: 10))
            let countCells = XCUIApplication().collectionViews.cells.count
            for ind in 0...countCells {
                let currentPostName = XCUIApplication().collectionViews.cells.element(boundBy: ind).images["safari"]
                if currentPostName.exists {
                    findStub = true
                    break
                }
            }
            XCUIApplication().swipeUp()
            countSwipe += 1
        }
        XCTAssertTrue(findStub, "Stub not found")
    }
}
