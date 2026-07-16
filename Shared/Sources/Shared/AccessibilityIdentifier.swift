public enum AccessibilityIdentifier {
    public enum Feed {
        public static let list = "feed.list"
        public static let searchResults = "search.results"
        public static let settingsButton = "settings.button"
        public static let searchSortMenu = "search.sort.menu"
        public static let searchDateMenu = "search.date.menu"

        public static func category(_ value: String) -> String {
            "feed.category.\(value)"
        }

        public static func post(_ id: Int) -> String {
            "feed.post.\(id)"
        }
    }

    public enum Settings {
        public static let form = "settings.form"
        public static let close = "settings.close"
        public static let showThumbnails = "settings.showThumbnails"
        public static let compactFeed = "settings.compactFeed"
        public static let dimReadPosts = "settings.dimReadPosts"
    }

    public enum Login {
        public static let close = "login.close"
        public static let username = "login.username"
        public static let password = "login.password"
        public static let signIn = "login.signIn"
    }

    public enum Comments {
        public static let list = "comments.list"
        public static let nextCommentButton = "comments.nextCommentButton"

        public static func comment(_ id: Int) -> String {
            "comments.comment.\(id)"
        }

        public static func vote(_ id: Int) -> String {
            "comments.vote.\(id)"
        }
    }

    public enum Browser {
        public static let view = "browser.view"
        public static let fixtureArticle = "browser.fixtureArticle"
        public static let missingFixtureArticle = "browser.fixtureArticle.missing"
        public static let commentsSheetHandle = "browser.commentsSheet.handle"
        public static let collapsedCommentsHeader = "browser.commentsSheet.collapsedHeader"
        public static let expandedCommentsTitle = "browser.commentsSheet.expandedTitle"
    }
}
