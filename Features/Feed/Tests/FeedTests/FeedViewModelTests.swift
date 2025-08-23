import XCTest
@testable import Feed
import Domain

final class FeedViewModelTests: XCTestCase {

    func testInitialState() {
        let viewModel = FeedViewModel()

        XCTAssertEqual(viewModel.posts.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertEqual(viewModel.postType, .news)
        XCTAssertNil(viewModel.error)
    }

    func testChangePostType() async {
        let viewModel = FeedViewModel()

        let initialType = viewModel.postType
        XCTAssertEqual(initialType, .news)

        await viewModel.changePostType(.ask)
        XCTAssertEqual(viewModel.postType, .ask)
    }
}
