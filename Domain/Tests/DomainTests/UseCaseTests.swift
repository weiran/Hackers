//
//  UseCaseTests.swift
//  DomainTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Data
@testable import Domain
import Foundation
@testable import Networking
import Testing

@Suite("Domain Use Case Integration Tests")
struct UseCaseTests {
    private let network = StubNetworkManager()
    private var postRepository: PostRepository { PostRepository(networkManager: network) }
    private var settingsRepository: SettingsRepository {
        SettingsRepository(userDefaults: InMemoryUserDefaults())
    }

    // MARK: - PostUseCase via PostRepository

    @MainActor
    @Test("Fetching posts parses feed metadata and deduplicates IDs")
    func fetchPostsParsesFeed() async throws {
        network.reset()
        network.enqueue(html: HTMLFixtures.feedPage)

        let postUseCase: any PostUseCase = postRepository
        let posts = try await postUseCase.getPosts(type: .news, page: 1, nextId: nil)

        #expect(posts.count == 2)

        let first = posts[0]
        #expect(first.id == 123)
        #expect(first.title == "Test Article Title")
        #expect(first.url.absoluteString == "https://example.com/article")
        #expect(first.age == "2023-01-01T10:00:00")
        #expect(first.commentsCount == 5)
        #expect(first.by == "testuser")
        #expect(first.score == 10)
        #expect(first.voteLinks?.upvote != nil)
        #expect(first.voteLinks?.unvote == nil)

        let second = posts[1]
        #expect(second.id == 456)
        #expect(second.upvoted)
        if let unvoteURL = second.voteLinks?.unvote?.absoluteString {
            #expect(unvoteURL.contains("how=un"))
        } else {
            Issue.record("Expected derived unvote link for hidden upvote")
        }
    }

    @MainActor
    @Test("Fetching individual Ask HN post injects top text comment")
    func fetchAskPostIncludesTopTextComment() async throws {
        network.reset()
        network.enqueue(html: HTMLFixtures.askPost)

        let postUseCase: any PostUseCase = postRepository
        let post = try await postUseCase.getPost(id: 999)

        #expect(post.text?.contains("Intro text") == true)
        #expect(post.comments?.count == 2)
        #expect(post.comments?.first?.id == -post.id)
        #expect(post.comments?.first?.text.contains("Intro text") == true)
    }

    @MainActor
    @Test("Fetching comments resolves comment permalink to story")
    func fetchPostFromCommentPermalink() async throws {
        network.reset()
        network.enqueue(html: HTMLFixtures.commentPermalink)
        network.enqueue(html: HTMLFixtures.storyWithComments)

        let postUseCase: any PostUseCase = postRepository
        let post = try await postUseCase.getPost(id: 604)

        #expect(post.id == 101)
        #expect(post.comments?.contains(where: { $0.id == 604 }) == true)
        let requested = network.urlsRequested.map(\.absoluteString)
        #expect(requested.count == 2)
        #expect(requested.contains { $0.hasPrefix("https://news.ycombinator.com/item?id=604") })
        #expect(requested.contains { $0.hasPrefix("https://news.ycombinator.com/item?id=101") })
    }

    @MainActor
    @Test("Comments endpoint returns parsed thread for post")
    func fetchCommentsForPost() async throws {
        network.reset()
        network.enqueue(html: HTMLFixtures.storyWithComments)
        let post = Post(
            id: 101,
            url: URL(string: "https://example.com/story")!,
            title: "Story",
            age: "3 hours ago",
            commentsCount: 3,
            by: "author",
            score: 42,
            postType: .news,
            upvoted: false
        )

        let commentUseCase: any CommentUseCase = postRepository
        let comments = try await commentUseCase.getComments(for: post)
        #expect(comments.count == 3)
        #expect(comments[0].id == 604)
        #expect(comments[0].level == 0)
        #expect(comments[1].id == 202)
        #expect(comments[1].level == 1)
        #expect(comments[2].id == 203)
        #expect(comments[2].upvoted == false)
    }

    // MARK: - VoteUseCase via PostRepository

    @MainActor
    @Test("Upvoting a post issues network request to HN vote endpoint")
    func upvotePostInvokesNetwork() async throws {
        network.reset()
        network.enqueue(html: "<html></html>")
        let voteUseCase: any VoteUseCase = postRepository

        let voteLinks = VoteLinks(
            upvote: URL(string: "vote?id=123&how=up")!,
            unvote: nil
        )
        let post = Post(
            id: 123,
            url: URL(string: "https://example.com")!,
            title: "Vote",
            age: "1 hour ago",
            commentsCount: 0,
            by: "upvoter",
            score: 10,
            postType: .news,
            upvoted: false,
            voteLinks: voteLinks
        )

        try await voteUseCase.upvote(post: post)

        #expect(network.urlsRequested.last?.absoluteString == "https://news.ycombinator.com/vote?id=123&how=up")
    }

    @MainActor
    @Test("Missing vote links throws unauthenticated error")
    func upvotePostWithoutLinksThrows() async {
        let voteUseCase: any VoteUseCase = postRepository
        let post = Post(
            id: 321,
            url: URL(string: "https://example.com")!,
            title: "Vote",
            age: "now",
            commentsCount: 0,
            by: "user",
            score: 1,
            postType: .news,
            upvoted: false
        )

        await #expect {
            try await voteUseCase.upvote(post: post)
        } throws: { error in
            guard let hackersError = error as? HackersKitError else { return false }
            if case .unauthenticated = hackersError { return true }
            return false
        }
    }

    // MARK: - SettingsUseCase via SettingsRepository

    @Test("Settings repository persists changes through protocol")
    func settingsUseCasePersistsValues() {
        var settingsUseCase: any SettingsUseCase = settingsRepository

        #expect(settingsUseCase.safariReaderMode == false)
        #expect(settingsUseCase.openInDefaultBrowser == false)
        #expect(settingsUseCase.showThumbnails == true)
        #expect(settingsUseCase.textSize == .medium)

        settingsUseCase.safariReaderMode = true
        settingsUseCase.openInDefaultBrowser = true
        settingsUseCase.showThumbnails = false
        settingsUseCase.textSize = .large

        #expect(settingsUseCase.safariReaderMode == true, "actual: \(settingsUseCase.safariReaderMode)")
        #expect(settingsUseCase.openInDefaultBrowser == true, "actual: \(settingsUseCase.openInDefaultBrowser)")
        #expect(settingsUseCase.showThumbnails == false, "actual: \(settingsUseCase.showThumbnails)")
        #expect(settingsUseCase.textSize == .large, "actual: \(settingsUseCase.textSize)")
    }
}

// MARK: - Supporting Test Doubles

final class StubNetworkManager: NetworkManagerProtocol, @unchecked Sendable {
    private(set) var urlsRequested: [URL] = []
    private var responseQueue: [Result<String, Error>] = []

    func enqueue(html: String) {
        responseQueue.append(.success(html))
    }

    func enqueue(error: Error) {
        responseQueue.append(.failure(error))
    }

    func get(url: URL) async throws -> String {
        urlsRequested.append(url)
        guard !responseQueue.isEmpty else { throw StubError.unexpectedRequest(url) }
        let response = responseQueue.removeFirst()
        switch response {
        case let .success(html):
            return html
        case let .failure(error):
            throw error
        }
    }

    func post(url: URL, body _: String) async throws -> String {
        urlsRequested.append(url)
        guard !responseQueue.isEmpty else { throw StubError.unexpectedRequest(url) }
        let response = responseQueue.removeFirst()
        switch response {
        case let .success(html):
            return html
        case let .failure(error):
            throw error
        }
    }

    func clearCookies() {}

    func containsCookie(for _: URL) -> Bool { false }

    func reset() {
        urlsRequested.removeAll()
        responseQueue.removeAll()
    }

    enum StubError: Error, CustomStringConvertible {
        case unexpectedRequest(URL)

        var description: String {
            switch self {
            case let .unexpectedRequest(url):
                return "Unexpected request for \(url.absoluteString)"
            }
        }
    }
}

final class InMemoryUserDefaults: UserDefaultsProtocol, @unchecked Sendable {
    private var storage: [String: Any] = [
        "safariReaderMode": false,
        "openInDefaultBrowser": false,
        "ShowThumbnails": true,
        "textSize": TextSize.medium.rawValue
    ]

    func bool(forKey defaultName: String) -> Bool {
        storage[defaultName] as? Bool ?? false
    }

    func integer(forKey defaultName: String) -> Int {
        storage[defaultName] as? Int ?? 0
    }

    func set(_ value: Bool, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func set(_ value: Int, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
}

enum HTMLFixtures {
    static let feedPage = """
    <html>
      <body>
        <table class=\"itemlist\">
          <tr class=\"athing submission\" id=\"123\">
            <td align=\"right\" valign=\"top\" class=\"title\"><span class=\"rank\">1.</span></td>
            <td valign=\"top\" class=\"votelinks\">
              <center>
                <a id='up_123' href='vote?id=123&how=up'>
                  <div class='votearrow' title='upvote'></div>
                </a>
              </center>
            </td>
            <td class=\"title\">
              <span class=\"titleline\">
                <a href=\"https://example.com/article\">Test Article Title</a>
              </span>
            </td>
          </tr>
          <tr>
            <td colspan=\"2\"></td>
            <td class=\"subtext\">
              <span class=\"score\">10 points</span>
              <span class=\"age\" title=\"2023-01-01T10:00:00\"><a href=\"item?id=123\">2 hours ago</a></span>
              <a class=\"hnuser\" href=\"user?id=testuser\">testuser</a>
              <span id=\"unv_123\"></span>
              <a href=\"item?id=123\">5&nbsp;comments</a>
            </td>
          </tr>
          <tr class=\"spacer\" style=\"height:5px\"></tr>
          <tr class=\"athing submission\" id=\"456\">
            <td align=\"right\" valign=\"top\" class=\"title\"><span class=\"rank\">2.</span></td>
            <td valign=\"top\" class=\"votelinks\">
              <center>
                <a id='up_456' class='clicky nosee' href='vote?id=456&how=up'>
                  <div class='votearrow' title='upvote'></div>
                </a>
              </center>
            </td>
            <td class=\"title\">
              <span class=\"titleline\">
                <a href=\"https://example.com/article2\">Already Upvoted</a>
              </span>
            </td>
          </tr>
          <tr>
            <td colspan=\"2\"></td>
            <td class=\"subtext\">
              <span class=\"score\">15 points</span>
              <span class=\"age\" title=\"2023-01-01T11:00:00\"><a href=\"item?id=456\">1 hour ago</a></span>
              <a class=\"hnuser\" href=\"user?id=second\">second</a>
              <span id=\"unv_456\">
                <a id='un_456' href='vote?id=456&how=un'>unvote</a>
              </span>
              <a href=\"item?id=456\">3&nbsp;comments</a>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """

    static let askPost = """
    <html>
      <body>
        <table class=\"fatitem\">
          <tr class=\"athing submission\" id=\"999\">
            <td align=\"right\" valign=\"top\" class=\"title\"><span class=\"rank\"></span></td>
            <td valign=\"top\" class=\"votelinks\"></td>
            <td class=\"title\">
              <span class=\"titleline\"><a href=\"item?id=999\">Ask HN?</a></span>
            </td>
          </tr>
          <tr>
            <td colspan=\"2\"></td>
            <td class=\"subtext\">
              <span class=\"score\">12 points</span>
              by <a href=\"user?id=asker\" class=\"hnuser\">asker</a>
              <span class=\"age\" title=\"2023-01-01T12:00:00\"><a href=\"item?id=999\">4 hours ago</a></span>
              <a href=\"item?id=999\">3&nbsp;comments</a>
            </td>
          </tr>
          <tr>
            <td colspan=\"2\"></td>
            <td>
              <div class=\"toptext\">Intro text<p>Details</p></div>
            </td>
          </tr>
        </table>
        <table class=\"comment-tree\">
          <tr class=\"athing comtr\" id=\"777\">
            <td>
              <table>
                <tr>
                  <td class=\"ind\" indent=\"0\"><img src=\"s.gif\" height=\"1\" width=\"0\"></td>
                  <td class=\"default\">
                    <div class=\"comment\">
                      <span class=\"age\">1 hour ago</span>
                      <a class=\"hnuser\" href=\"user?id=commenter\">commenter</a>
                      <div class=\"commtext c00\">First response</div>
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """

    static let commentPermalink = """
    <html>
      <body>
        <table class=\"fatitem\">
          <tr class=\"athing\" id=\"604\"></tr>
        </table>
        <span class=\"navs\">
          | <a href=\"item?id=101\">parent</a>
        </span>
      </body>
    </html>
    """

    static let storyWithComments = """
    <html>
      <body>
        <table class=\"fatitem\">
          <tr class=\"athing\" id=\"101\">
            <td>
              <span class=\"titleline\"><a href=\"https://example.com/story\">Story</a></span>
            </td>
          </tr>
          <tr>
            <td>
              <span class=\"score\">42 points</span>
              <span class=\"age\" title=\"2023-01-01T09:00:00\">3 hours ago</span>
              <a class=\"hnuser\" href=\"user?id=author\">author</a>
              <a href=\"item?id=101\">3 comments</a>
            </td>
          </tr>
        </table>
        <table class=\"comment-tree\">
          <tr class=\"athing comtr\" id=\"604\">
            <td>
              <table>
                <tr>
                  <td class=\"ind\" indent=\"0\"><img src=\"s.gif\" height=\"1\" width=\"0\"></td>
                  <td valign=\"top\" class=\"votelinks\"><center><a id='up_604' href='vote?id=604&how=up&goto=item%3Fid%3D101'><div class='votearrow' title='upvote'></div></a></center></td>
                  <td class=\"default\">
                    <span class=\"comhead\">
                      <a class=\"hnuser\">commenter</a>
                      <span class=\"age\">2 hours ago</span>
                    </span>
                    <div class=\"comment\">
                      <div class=\"commtext c00\">Permalink comment</div>
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr class=\"athing comtr\" id=\"202\">
            <td>
              <table>
                <tr>
                  <td class=\"ind\" indent=\"40\"><img src=\"s.gif\" height=\"1\" width=\"40\"></td>
                  <td valign=\"top\" class=\"votelinks\"><center><a id='up_202' href='vote?id=202&how=up&goto=item%3Fid%3D101'><div class='votearrow' title='upvote'></div></a></center></td>
                  <td class=\"default\">
                    <span class=\"comhead\">
                      <a class=\"hnuser\">child</a>
                      <span class=\"age\">2 hours ago</span>
                    </span>
                    <div class=\"comment\">
                      <div class=\"commtext c00\">Child</div>
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr class=\"athing comtr\" id=\"203\">
            <td>
              <table>
                <tr>
                  <td class=\"ind\" indent=\"80\"><img src=\"s.gif\" height=\"1\" width=\"80\"></td>
                  <td valign=\"top\" class=\"votelinks\"><center><a id='up_203' href='vote?id=203&how=up&goto=item%3Fid%3D101'><div class='votearrow' title='upvote'></div></a></center></td>
                  <td class=\"default\">
                    <span class=\"comhead\">
                      <a class=\"hnuser\">grandchild</a>
                      <span class=\"age\">1 hour ago</span>
                    </span>
                    <div class=\"comment\">
                      <div class=\"commtext c00\">Grandchild</div>
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </table>
      </body>
    </html>
    """
}
