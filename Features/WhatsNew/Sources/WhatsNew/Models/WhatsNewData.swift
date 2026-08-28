//
//  WhatsNewData.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

public struct WhatsNewData: Sendable {
    public let title: String
    public let items: [WhatsNewItem]

    public init(title: String, items: [WhatsNewItem]) {
        self.title = title
        self.items = items
    }

    public static func currentWhatsNew() -> WhatsNewData {
        let joinConversation = WhatsNewItem(
            title: "Join the Conversation",
            subtitle: "Share your take on any story with the new comment composer, right where you read.",
            systemImage: "text.bubble.fill",
        )

        let replyToComments = WhatsNewItem(
            title: "Reply to Comments",
            subtitle: "Dive into threads and reply to any comment to keep the discussion going.",
            systemImage: "arrowshape.turn.up.left.fill",
        )

        let upvoteComments = WhatsNewItem(
            title: "Upvote the Best",
            subtitle: "Sign in with your Hacker News account to comment and upvote — it all counts on the site too.",
            systemImage: "arrow.up.circle.fill",
        )

        return WhatsNewData(
            title: "What's New in Hackers 5.5.0",
            items: [joinConversation, replyToComments, upvoteComments],
        )
    }
}
