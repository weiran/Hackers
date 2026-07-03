import CoreGraphics

enum PostCommentsSheetMetrics {
    static let initialCollapsedHeight: CGFloat = 150
    static let collapsedTopCornerRadius: CGFloat = 24
    static let collapsedBrowserControlsHeight: CGFloat = 44
    static let collapsedBrowserControlsSpacing: CGFloat = 12
    static let collapsedBrowserControlsMargin: CGFloat = 24

    static var defaultCollapsedBrowserScrollContentInset: CGFloat {
        collapsedBrowserControlsHeight
            + collapsedBrowserControlsSpacing
            + collapsedBrowserControlsMargin
    }

    static func browserScrollContentInset(controlsHeight: CGFloat) -> CGFloat {
        max(controlsHeight, collapsedBrowserControlsHeight)
            + collapsedBrowserControlsSpacing
            + collapsedBrowserControlsMargin
    }
}
