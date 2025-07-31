//
//  CommentsView.swift
//  Hackers
//
//  Created by Weiran Zhang on SwiftUI Migration.
//  Copyright © 2024 Glass Umbrella. All rights reserved.
//

import SwiftUI

struct CommentsView: View {
    let post: Post
    @EnvironmentObject private var navigationStore: NavigationStore
    @State private var comments: [Comment] = []
    @State private var isLoading = false
    @State private var currentPost: Post
    @State private var commentsController = CommentsController()

    init(post: Post) {
        self.post = post
        self._currentPost = State(initialValue: post)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Post header
                VStack(alignment: .leading, spacing: 8) {
                    Text(currentPost.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(UIColor(named: "titleTextColor")!))

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .foregroundColor(currentPost.upvoted ? Color(UIColor(named: "upvotedColor")!) : .secondary)
                            Text("\(currentPost.score)")
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "message")
                                .foregroundColor(.secondary)
                            Text("\(currentPost.commentsCount)")
                                .foregroundColor(.secondary)
                        }

                        Text("by \(currentPost.by)")
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(currentPost.age)
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)

                    if let text = currentPost.text, !text.isEmpty {
                        Text(text)
                            .padding(.top, 8)
                            .foregroundColor(Color(UIColor(named: "textColor")!))
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))

                Divider()

                // Comments section
                if isLoading {
                    ProgressView("Loading comments...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if comments.isEmpty {
                    EmptyStateView("No comments yet")
                } else {
                    List(commentsController.visibleComments, id: \.id) { comment in
                        CommentRowView(comment: comment) {
                            toggleCommentVisibility(comment)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await loadComments()
            }
            .task {
                await loadComments()
            }
        }
    }

    private func loadComments() async {
        isLoading = true

        do {
            // Load post with comments if not already loaded
            let postWithComments: Post
            if currentPost.comments == nil {
                postWithComments = try await HackersKit.shared.getPost(id: currentPost.id, includeAllComments: true)
                currentPost = postWithComments
            } else {
                postWithComments = currentPost
            }

            // Set comments
            let loadedComments = postWithComments.comments ?? []
            comments = loadedComments
            commentsController.comments = loadedComments
            currentPost.commentsCount = loadedComments.count
        } catch {
            print("Error loading comments: \(error)")
            // TODO: Show error state
        }

        isLoading = false
    }

    private func toggleCommentVisibility(_ comment: Comment) {
        let _ = commentsController.toggleChildrenVisibility(of: comment)
        // Trigger UI update by reassigning the comments array
        comments = commentsController.comments
    }
}

struct CommentRowView: View {
    let comment: Comment
    let onToggle: () -> Void

    init(comment: Comment, onToggle: @escaping () -> Void = {}) {
        self.comment = comment
        self.onToggle = onToggle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(comment.by)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text(comment.age)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if comment.upvoted {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Color(UIColor(named: "upvotedColor")!))
                        .font(.caption)
                }

                // Show visibility indicator
                if comment.visibility == .compact {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Only show full text if comment is visible
            if comment.visibility == .visible {
                HTMLText(comment.text)
                    .foregroundColor(Color(UIColor(named: "textColor")!))
            } else if comment.visibility == .compact {
                Text("...")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .padding(.leading, CGFloat(comment.level * 16))
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .opacity(comment.visibility == .hidden ? 0 : 1)
        .frame(height: comment.visibility == .hidden ? 0 : nil)
    }
}

// Simple HTML text view for now - can be enhanced later
struct HTMLText: View {
    let htmlString: String

    var body: some View {
        Text(htmlString.strippingHTML())
    }
}

extension String {
    func strippingHTML() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#x27;", with: "'")
    }
}

#Preview {
    let samplePost = Post(
        id: 1,
        url: URL(string: "https://ycombinator.com")!,
        title: "Sample Post Title",
        age: "2 hours ago",
        commentsCount: 42,
        by: "user123",
        score: 156,
        postType: .news,
        upvoted: false
    )

    CommentsView(post: samplePost)
        .environmentObject(NavigationStore())
}
