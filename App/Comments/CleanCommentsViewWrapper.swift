//
//  CleanCommentsViewWrapper.swift
//  Hackers
//
//  Wrapper to integrate the clean architecture CommentsView
//

import SwiftUI
import Comments
import Domain

struct CleanCommentsViewWrapper: View {
    let post: Post // Accept HackersKit Post
    @EnvironmentObject var navigationStore: NavigationStore
    @StateObject private var viewModel: CommentsViewModelWrapper

    init(post: Post) {
        self.post = post
        self._viewModel = StateObject(wrappedValue: CommentsViewModelWrapper(post: post.toDomain()))
    }

    var body: some View {
        CleanCommentsView<NavigationStore>(
            post: post.toDomain(),
            viewModel: viewModel.commentsViewModel
        )
        .environmentObject(navigationStore)
    }
}

// Wrapper that handles HTML parsing for comments
class CommentsViewModelWrapper: ObservableObject {
    let commentsViewModel: CommentsViewModel

    init(post: Domain.Post) {
        self.commentsViewModel = CommentsViewModel(post: post)
        self.commentsViewModel.onCommentsLoaded = { [weak self] comments in
            self?.parseCommentsHTML(comments)
        }
    }

    private func parseCommentsHTML(_ comments: [Domain.Comment]) {
        // Parse HTML for each comment using the existing CommentHTMLParser
        for comment in comments {
            comment.parsedText = CommentHTMLParser.parseHTMLText(comment.text)
        }
    }
}
