import Testing
@testable import Comments
import Domain
import Shared

@Suite("Comments Module Tests")
struct SimpleCommentsTests {
    
    @Suite("CommentsViewModel")
    struct ViewModelTests {
        @Test("ViewModel initializes with correct default values")
        func viewModelInitialization() {
            // Given
            let post = Post(
                id: 1,
                url: URL(string: "https://example.com")!,
                title: "Test Post",
                age: "1 hour ago",
                commentsCount: 5,
                by: "testuser",
                score: 100,
                postType: .news,
                upvoted: false
            )
            
            // When
            let viewModel = CommentsViewModel(post: post)
            
            // Then
            #expect(viewModel.post.id == 1)
            #expect(viewModel.post.title == "Test Post")
            #expect(viewModel.comments.isEmpty)
            #expect(viewModel.visibleComments.isEmpty)
            #expect(!viewModel.isLoading)
            #expect(viewModel.error == nil)
        }
    }
    
    @Suite("Comment Model")
    struct CommentTests {
        @Test("Comment initializes with correct values")
        func commentInitialization() {
            // Given & When
            let comment = Comment(
                id: 1,
                age: "2 hours ago",
                text: "This is a test comment",
                by: "testuser",
                level: 0,
                upvoted: false,
                visibility: .visible
            )
            
            // Then
            #expect(comment.id == 1)
            #expect(comment.age == "2 hours ago")
            #expect(comment.text == "This is a test comment")
            #expect(comment.by == "testuser")
            #expect(comment.level == 0)
            #expect(!comment.upvoted)
            #expect(comment.visibility == .visible)
        }
        
        @Test("Comment visibility transitions", arguments: [
            (from: CommentVisibilityType.visible, to: CommentVisibilityType.compact),
            (from: CommentVisibilityType.compact, to: CommentVisibilityType.hidden),
            (from: CommentVisibilityType.hidden, to: CommentVisibilityType.visible)
        ])
        func commentVisibilityToggle(from: CommentVisibilityType, to: CommentVisibilityType) {
            // Given
            let comment = Comment(
                id: 1,
                age: "1 hour ago",
                text: "Test",
                by: "user",
                level: 0,
                upvoted: false,
                visibility: from
            )
            
            // When
            comment.visibility = to
            
            // Then
            #expect(comment.visibility == to)
        }
        
        @Test("Comment upvote state toggles correctly", arguments: [false, true])
        func commentUpvoteToggle(initialState: Bool) {
            // Given
            let comment = Comment(
                id: 1,
                age: "1 hour ago",
                text: "Test",
                by: "user",
                level: 0,
                upvoted: initialState,
                visibility: .visible
            )
            
            // When
            comment.upvoted = !initialState
            
            // Then
            #expect(comment.upvoted == !initialState)
        }
        
        @Test("Comment equality based on ID")
        func commentEquality() {
            // Given
            let comment1 = Comment(
                id: 1,
                age: "1 hour ago",
                text: "First",
                by: "user1",
                level: 0,
                upvoted: false,
                visibility: .visible
            )
            
            let comment2 = Comment(
                id: 1,
                age: "2 hours ago",
                text: "Different text",
                by: "user2",
                level: 1,
                upvoted: true,
                visibility: .hidden
            )
            
            let comment3 = Comment(
                id: 2,
                age: "1 hour ago",
                text: "First",
                by: "user1",
                level: 0,
                upvoted: false,
                visibility: .visible
            )
            
            // Then
            #expect(comment1 == comment2) // Same ID
            #expect(comment1 != comment3) // Different ID
        }
    }
    
    @Suite("Post with Comments")
    struct PostTests {
        @Test("Post can have comments attached", arguments: [0, 1, 5, 10])
        func postWithComments(commentCount: Int) {
            // Given
            var post = Post(
                id: 1,
                url: URL(string: "https://example.com")!,
                title: "Test Post",
                age: "1 hour ago",
                commentsCount: commentCount,
                by: "testuser",
                score: 100,
                postType: .news,
                upvoted: false
            )
            
            let comments = (1...commentCount).map { index in
                Comment(
                    id: index,
                    age: "\(index * 10) min ago",
                    text: "Comment \(index)",
                    by: "user\(index)",
                    level: index % 3, // Vary levels
                    upvoted: index % 2 == 0,
                    visibility: .visible
                )
            }
            
            // When
            post.comments = comments.isEmpty ? nil : comments
            
            // Then
            if commentCount == 0 {
                #expect(post.comments == nil)
            } else {
                #expect(post.comments?.count == commentCount)
                #expect(post.comments?.first?.id == 1)
                #expect(post.comments?.last?.id == commentCount)
            }
        }
        
        @Test("Post types cover all cases", arguments: PostType.allCases)
        func postTypes(type: PostType) {
            // Given
            let post = Post(
                id: 1,
                url: URL(string: "https://example.com")!,
                title: "Test \(type.rawValue)",
                age: "1 hour ago",
                commentsCount: 0,
                by: "testuser",
                score: 100,
                postType: type,
                upvoted: false
            )
            
            // Then
            #expect(post.postType == type)
            #expect(PostType.allCases.contains(type))
        }
    }
    
    @Suite("Comment Tree Structure")
    struct CommentTreeTests {
        @Test("Comments maintain hierarchical levels")
        func commentHierarchy() {
            // Given
            let comments = [
                Comment(id: 1, age: "1h", text: "Root 1", by: "user1", level: 0, upvoted: false, visibility: .visible),
                Comment(id: 2, age: "50m", text: "Child 1.1", by: "user2", level: 1, upvoted: false, visibility: .visible),
                Comment(id: 3, age: "45m", text: "Child 1.2", by: "user3", level: 1, upvoted: false, visibility: .visible),
                Comment(id: 4, age: "40m", text: "Grandchild 1.1.1", by: "user4", level: 2, upvoted: false, visibility: .visible),
                Comment(id: 5, age: "30m", text: "Root 2", by: "user5", level: 0, upvoted: false, visibility: .visible)
            ]
            
            // Then
            #expect(comments.filter { $0.level == 0 }.count == 2) // 2 root comments
            #expect(comments.filter { $0.level == 1 }.count == 2) // 2 child comments
            #expect(comments.filter { $0.level == 2 }.count == 1) // 1 grandchild comment
            
            // Verify structure
            let roots = comments.filter { $0.level == 0 }
            let children = comments.filter { $0.level == 1 }
            let grandchildren = comments.filter { $0.level == 2 }
            
            #expect(roots.map { $0.id }.sorted() == [1, 5])
            #expect(children.map { $0.id }.sorted() == [2, 3])
            #expect(grandchildren.map { $0.id } == [4])
        }
        
        @Test("Visible comments filter works correctly")
        func visibleCommentsFilter() {
            // Given
            let comments = [
                Comment(id: 1, age: "1h", text: "Visible", by: "user1", level: 0, upvoted: false, visibility: .visible),
                Comment(id: 2, age: "50m", text: "Hidden", by: "user2", level: 1, upvoted: false, visibility: .hidden),
                Comment(id: 3, age: "45m", text: "Compact", by: "user3", level: 1, upvoted: false, visibility: .compact),
                Comment(id: 4, age: "40m", text: "Visible", by: "user4", level: 2, upvoted: false, visibility: .visible)
            ]
            
            // When
            let visibleComments = comments.filter { $0.visibility != .hidden }
            
            // Then
            #expect(visibleComments.count == 3)
            #expect(visibleComments.map { $0.id }.sorted() == [1, 3, 4])
        }
    }
}