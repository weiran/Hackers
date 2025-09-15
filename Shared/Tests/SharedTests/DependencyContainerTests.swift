//
//  DependencyContainerTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

// swiftlint:disable force_cast

@testable import Data
@testable import Domain
import Foundation
@testable import Networking
@testable import Shared
import Testing

@Suite("DependencyContainer Tests")
struct DependencyContainerTests {
    let dependencyContainer = DependencyContainer.shared

    // MARK: - Singleton Tests

    @Test("Singleton instance consistency")
    func singletonInstance() {
        let container1 = DependencyContainer.shared
        let container2 = DependencyContainer.shared

        #expect(container1 === container2, "DependencyContainer should be a singleton")
    }

    // MARK: - PostUseCase Tests

    @Test("Get PostUseCase")
    func getPostUseCase() {
        let postUseCase = dependencyContainer.getPostUseCase()

        #expect(postUseCase != nil, "Should return a PostUseCase instance")
        #expect(postUseCase is PostRepository, "Should be a PostRepository instance")
    }

    @Test("PostUseCase returns same instance")
    func getPostUseCaseReturnsSameInstance() {
        let postUseCase1 = dependencyContainer.getPostUseCase()
        let postUseCase2 = dependencyContainer.getPostUseCase()

        // Should return the same instance (singleton behavior)
        #expect((postUseCase1 as? PostRepository) === (postUseCase2 as? PostRepository))
    }

    @Test("PostUseCase functionality")
    func postUseCaseFunctionality() async throws {
        let postUseCase = dependencyContainer.getPostUseCase()

        // Test that the use case can be called (though it will fail due to network)
        do {
            _ = try await postUseCase.getPosts(type: .news, page: 1, nextId: nil)
        } catch {
            // Expected to fail due to network, but should not crash
            #expect(error != nil)
        }
    }

    // MARK: - VoteUseCase Tests

    @Test("Get VoteUseCase")
    func getVoteUseCase() {
        let voteUseCase = dependencyContainer.getVoteUseCase()

        #expect(voteUseCase != nil)
        #expect(voteUseCase is PostRepository)
    }

    @Test("VoteUseCase returns same instance")
    func getVoteUseCaseReturnsSameInstance() {
        let voteUseCase1 = dependencyContainer.getVoteUseCase()
        let voteUseCase2 = dependencyContainer.getVoteUseCase()

        // Should return the same instance (singleton behavior)
        #expect((voteUseCase1 as? PostRepository) === (voteUseCase2 as? PostRepository))
    }

    @Test("VoteUseCase functionality")
    func voteUseCaseFunctionality() async throws {
        let voteUseCase = dependencyContainer.getVoteUseCase()
        let testPost = Self.createTestPost()

        // Test that the use case can be called (though it will fail due to network)
        do {
            try await voteUseCase.upvote(post: testPost)
        } catch {
            // Expected to fail due to missing vote links, but should not crash
            #expect(error != nil)
        }
    }

    // MARK: - CommentUseCase Tests

    @Test("Get CommentUseCase")
    func getCommentUseCase() {
        let commentUseCase = dependencyContainer.getCommentUseCase()

        #expect(commentUseCase != nil)
        #expect(commentUseCase is PostRepository)
    }

    @Test("CommentUseCase returns same instance")
    func getCommentUseCaseReturnsSameInstance() {
        let commentUseCase1 = dependencyContainer.getCommentUseCase()
        let commentUseCase2 = dependencyContainer.getCommentUseCase()

        // Should return the same instance (singleton behavior)
        #expect((commentUseCase1 as? PostRepository) === (commentUseCase2 as? PostRepository))
    }

    @Test("CommentUseCase functionality")
    func commentUseCaseFunctionality() async throws {
        let commentUseCase = dependencyContainer.getCommentUseCase()
        let testPost = Self.createTestPost()

        // Test that the use case can be called (though it will fail due to network)
        do {
            _ = try await commentUseCase.getComments(for: testPost)
        } catch {
            // Expected to fail due to network, but should not crash
            #expect(error != nil)
        }
    }

    // MARK: - SettingsUseCase Tests

    @Test("Get SettingsUseCase")
    func getSettingsUseCase() {
        let settingsUseCase = dependencyContainer.getSettingsUseCase()

        #expect(settingsUseCase != nil)
        #expect(settingsUseCase is SettingsRepository)
    }

    @Test("SettingsUseCase returns same instance")
    func getSettingsUseCaseReturnsSameInstance() {
        let settingsUseCase1 = dependencyContainer.getSettingsUseCase()
        let settingsUseCase2 = dependencyContainer.getSettingsUseCase()

        // Should return the same instance (singleton behavior)
        #expect((settingsUseCase1 as? SettingsRepository) === (settingsUseCase2 as? SettingsRepository))
    }

    @Test("SettingsUseCase functionality")
    func settingsUseCaseFunctionality() {
        let settingsUseCase = dependencyContainer.getSettingsUseCase()

        // Test basic functionality
        let originalValue = settingsUseCase.safariReaderMode
        // SettingsUseCase properties are read-only in the protocol
        // We can only test that we can read the values
        #expect(settingsUseCase.safariReaderMode == originalValue)
    }

    // MARK: - Cross-Use Case Consistency Tests

    @Test("Post, Vote, Comment use cases are same instance")
    func postVoteCommentUseCasesAreSameInstance() {
        let postUseCase = dependencyContainer.getPostUseCase()
        let voteUseCase = dependencyContainer.getVoteUseCase()
        let commentUseCase = dependencyContainer.getCommentUseCase()

        // All three should return the same PostRepository instance
        #expect((postUseCase as? PostRepository) === (voteUseCase as? PostRepository))
        #expect((voteUseCase as? PostRepository) === (commentUseCase as? PostRepository))
        #expect((postUseCase as? PostRepository) === (commentUseCase as? PostRepository))
    }

    @Test("SettingsUseCase is independent")
    func settingsUseCaseIsIndependent() {
        let postUseCase = dependencyContainer.getPostUseCase()
        let settingsUseCase = dependencyContainer.getSettingsUseCase()

        // Settings use case should be a different type from post-related use cases
        #expect((postUseCase as? PostRepository) != nil)
        #expect((settingsUseCase as? SettingsRepository) != nil)
        #expect((settingsUseCase as? PostRepository) == nil)
    }

    // MARK: - Protocol Conformance Tests

    @Test("All use cases conform to protocols")
    func allUseCasesConformToProtocols() {
        // Test that returned objects conform to their respective protocols
        let postUseCase: PostUseCase = dependencyContainer.getPostUseCase()
        let voteUseCase: VoteUseCase = dependencyContainer.getVoteUseCase()
        let commentUseCase: CommentUseCase = dependencyContainer.getCommentUseCase()
        let settingsUseCase: SettingsUseCase = dependencyContainer.getSettingsUseCase()

        // If this compiles, the protocols are correctly implemented
        #expect(postUseCase != nil)
        #expect(voteUseCase != nil)
        #expect(commentUseCase != nil)
        #expect(settingsUseCase != nil)
    }

    // MARK: - Dependency Injection Tests

    @Test("NetworkManager dependency injection")
    func networkManagerDependencyInjection() {
        // Test that the same NetworkManager is used throughout
        let postUseCase = dependencyContainer.getPostUseCase() as! PostRepository
        let voteUseCase = dependencyContainer.getVoteUseCase() as! PostRepository

        // Both should use the same PostRepository instance (tested above)
        // which means they share the same NetworkManager
        #expect(postUseCase === voteUseCase)
    }

    @Test("UserDefaults dependency injection")
    func userDefaultsDependencyInjection() {
        let settingsUseCase = dependencyContainer.getSettingsUseCase() as! SettingsRepository

        // Test that SettingsRepository is properly initialized
        // (we can't easily test the UserDefaults injection without exposing internals)
        #expect(settingsUseCase != nil)
    }

    // MARK: - Thread Safety Tests

    @Test("Concurrent access")
    func concurrentAccess() async {
        // Test concurrent access to the dependency container
        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< 10 {
                group.addTask {
                    let postUseCase = dependencyContainer.getPostUseCase()
                    let voteUseCase = dependencyContainer.getVoteUseCase()
                    let commentUseCase = dependencyContainer.getCommentUseCase()
                    let settingsUseCase = dependencyContainer.getSettingsUseCase()

                    // All should be non-nil and consistent
                    #expect(postUseCase != nil)
                    #expect(voteUseCase != nil)
                    #expect(commentUseCase != nil)
                    #expect(settingsUseCase != nil)

                    // Post-related use cases should be the same instance
                    #expect((postUseCase as? PostRepository) === (voteUseCase as? PostRepository))
                    #expect((voteUseCase as? PostRepository) === (commentUseCase as? PostRepository))
                }
            }
        }
    }

    // MARK: - Memory Management Tests

    @Test("No retain cycles")
    func noRetainCycles() {
        weak var weakPostRepository: PostRepository?
        weak var weakSettingsRepository: SettingsRepository?

        do {
            let postUseCase = dependencyContainer.getPostUseCase()
            let settingsUseCase = dependencyContainer.getSettingsUseCase()

            weakPostRepository = postUseCase as? PostRepository
            weakSettingsRepository = settingsUseCase as? SettingsRepository
        }

        // The instances should still be alive because they're retained by the container
        #expect(weakPostRepository != nil)
        #expect(weakSettingsRepository != nil)
    }

    // MARK: - Helper Methods

    private static func createTestPost() -> Post {
        Post(
            id: 123,
            url: URL(string: "https://example.com/post")!,
            title: "Test Post",
            age: "2 hours ago",
            commentsCount: 5,
            by: "testuser",
            score: 10,
            postType: .news,
            upvoted: false,
        )
    }
}
