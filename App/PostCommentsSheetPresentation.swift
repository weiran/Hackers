import CoreGraphics
import UIKit

enum SheetState {
    case collapsed
    case expanded
}

enum PostCommentsSheetMetrics {
    static let initialCollapsedHeight: CGFloat = 150
    static let collapsedTopCornerRadius: CGFloat = 24
    static let collapsedBrowserControlsHeight: CGFloat = 44
    static let collapsedBrowserControlsSpacing: CGFloat = 12
    static let collapsedBrowserControlsMargin: CGFloat = 24
    static let handleAreaHeight: CGFloat = 22
    static let verticalDragBias: CGFloat = 1.2

    static var defaultCollapsedBrowserObscuredBottomInset: CGFloat {
        collapsedBrowserControlsHeight
            + collapsedBrowserControlsSpacing
            + collapsedBrowserControlsMargin
    }

    static func browserObscuredBottomInset(controlsHeight: CGFloat) -> CGFloat {
        max(controlsHeight, collapsedBrowserControlsHeight)
            + collapsedBrowserControlsSpacing
            + collapsedBrowserControlsMargin
    }
}

struct PostCommentsSheetPresentation {
    var sheetState: SheetState
    var dragTranslation: CGFloat = 0
    var isTrackingDrag = false
    var dragStartAllowsSheetDrag = false
    var isHandleDragActive = false
    var suppressesCollapsedUpvote = false

    var isExpanded: Bool {
        sheetState == .expanded
    }

    var isCollapsed: Bool {
        !isExpanded
    }

    var isInteractiveMove: Bool {
        isTrackingDrag || isHandleDragActive
    }

    var showsCollapsedControls: Bool {
        sheetState == .collapsed && !isTrackingDrag && !isHandleDragActive
    }

    init(sheetState: SheetState) {
        self.sheetState = sheetState
    }

    mutating func expand() {
        sheetState = .expanded
    }

    mutating func collapse() {
        guard isExpanded else { return }
        sheetState = .collapsed
        dragTranslation = 0
        isTrackingDrag = false
        dragStartAllowsSheetDrag = false
        isHandleDragActive = false
    }

    mutating func updateSheetDrag(
        startX: CGFloat,
        translation: CGSize,
        systemBackGestureEdgeWidth: CGFloat,
        isScrollAtTop: Bool
    ) {
        guard !isHandleDragActive else { return }
        guard startX > systemBackGestureEdgeWidth else { return }

        let verticalMovement = abs(translation.height)
        let horizontalMovement = abs(translation.width)
        let isMostlyVertical = verticalMovement > horizontalMovement * PostCommentsSheetMetrics.verticalDragBias

        if !isTrackingDrag {
            guard isExpanded, isScrollAtTop, isMostlyVertical, translation.height > 0 else { return }
            dragStartAllowsSheetDrag = true
            isTrackingDrag = true
            suppressesCollapsedUpvote = true
        }

        guard dragStartAllowsSheetDrag else { return }
        dragTranslation = max(0, translation.height)
    }

    mutating func canEndSheetDrag(
        startX: CGFloat,
        systemBackGestureEdgeWidth: CGFloat
    ) -> Bool {
        guard !isHandleDragActive else { return false }
        guard startX > systemBackGestureEdgeWidth, dragStartAllowsSheetDrag else {
            resetDragTracking()
            return false
        }
        return true
    }

    mutating func updateHandleDrag(
        startX: CGFloat,
        translationHeight: CGFloat,
        systemBackGestureEdgeWidth: CGFloat
    ) {
        guard startX > systemBackGestureEdgeWidth else { return }
        if !isHandleDragActive {
            suppressesCollapsedUpvote = true
        }
        isHandleDragActive = true
        dragTranslation = translationHeight
    }

    mutating func canEndHandleDrag(
        startX: CGFloat,
        systemBackGestureEdgeWidth: CGFloat
    ) -> Bool {
        guard isHandleDragActive else { return false }
        guard startX > systemBackGestureEdgeWidth else {
            isHandleDragActive = false
            resetDragTracking()
            return false
        }
        return true
    }

    mutating func settle(
        predictedTranslation: CGFloat,
        expandedTop: CGFloat,
        collapsedTop: CGFloat
    ) {
        let baseTop = isExpanded ? expandedTop : collapsedTop
        let predictedTop = baseTop + predictedTranslation
        let midpoint = (expandedTop + collapsedTop) / 2
        sheetState = predictedTop <= midpoint ? .expanded : .collapsed
        dragTranslation = 0
        isTrackingDrag = false
        dragStartAllowsSheetDrag = false
        isHandleDragActive = false
    }

    mutating func resetDragTracking() {
        isTrackingDrag = false
        dragStartAllowsSheetDrag = false
        dragTranslation = 0
    }

    mutating func finishUpvoteSuppressionIfIdle() {
        guard !isTrackingDrag, !isHandleDragActive else { return }
        suppressesCollapsedUpvote = false
    }
}

struct PostCommentsSheetLayout {
    let expandedTop: CGFloat
    let collapsedTop: CGFloat
    let alignedTop: CGFloat
    let controlsTop: CGFloat
    let expansionProgress: CGFloat
    let handleTopInset: CGFloat
    let expandedCommentsTopInset: CGFloat
    let contentFadeProgress: CGFloat

    init(
        safeInsets: UIEdgeInsets,
        screenSize: CGSize,
        collapsedHeight: CGFloat,
        controlsHeight: CGFloat,
        dragTranslation: CGFloat,
        isExpanded: Bool,
        expandedTopOverlayHeight: (CGFloat) -> CGFloat
    ) {
        expandedTop = 0
        collapsedTop = max(screenSize.height - (collapsedHeight + safeInsets.bottom), expandedTop)

        let baseTop = isExpanded ? expandedTop : collapsedTop
        let proposedTop = baseTop + dragTranslation
        alignedTop = min(max(proposedTop, expandedTop), collapsedTop)

        let controlsOffset = max(controlsHeight, PostCommentsSheetMetrics.collapsedBrowserControlsHeight)
            + PostCommentsSheetMetrics.collapsedBrowserControlsSpacing
        controlsTop = alignedTop - controlsOffset

        if collapsedTop > expandedTop {
            expansionProgress = 1 - ((alignedTop - expandedTop) / (collapsedTop - expandedTop))
        } else {
            expansionProgress = isExpanded ? 1 : 0
        }

        handleTopInset = safeInsets.top * min(max(expansionProgress, 0), 1)
        expandedCommentsTopInset = expandedTopOverlayHeight(safeInsets.top)
        contentFadeProgress = min(max(expansionProgress, 0), 1)
    }
}
