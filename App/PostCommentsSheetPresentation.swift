import CoreGraphics
import SwiftUI
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

    static var collapsedBrowserBottomInset: CGFloat {
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
    var scrollDragStartedFromSettledTop = false
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
        scrollDragStartedFromSettledTop = false
        isHandleDragActive = false
    }

    mutating func updateScrollDragEligibility(
        oldPhase: ScrollPhase,
        newPhase: ScrollPhase,
        isAtRestingTop: Bool
    ) {
        switch (oldPhase, newPhase) {
        case (.idle, .tracking), (.idle, .interacting):
            scrollDragStartedFromSettledTop = isAtRestingTop
        case (_, .interacting):
            break
        default:
            scrollDragStartedFromSettledTop = false
        }
    }

    mutating func updateSheetDrag(
        startX: CGFloat,
        translation: CGSize,
        systemBackGestureEdgeWidth: CGFloat
    ) {
        guard !isHandleDragActive else { return }
        guard startX > systemBackGestureEdgeWidth else { return }

        let verticalMovement = abs(translation.height)
        let horizontalMovement = abs(translation.width)
        let isMostlyVertical = verticalMovement > horizontalMovement * PostCommentsSheetMetrics.verticalDragBias

        if !isTrackingDrag {
            let startsSheetDrag = (isCollapsed && isMostlyVertical)
                || (isExpanded && scrollDragStartedFromSettledTop && isMostlyVertical && translation.height > 0)
            guard startsSheetDrag else { return }
            dragStartAllowsSheetDrag = true
            isTrackingDrag = true
            suppressesCollapsedUpvote = true
        }

        guard dragStartAllowsSheetDrag else { return }
        dragTranslation = isExpanded ? max(0, translation.height) : translation.height
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

    mutating func updateHandleDrag(translationHeight: CGFloat) {
        if !isHandleDragActive {
            suppressesCollapsedUpvote = true
        }
        isHandleDragActive = true
        dragTranslation = translationHeight
    }

    mutating func canEndHandleDrag() -> Bool {
        isHandleDragActive
    }

    mutating func cancelHandleDrag() {
        dragTranslation = 0
        isHandleDragActive = false
    }

    mutating func updateExpandedToolbarDrag(
        startX: CGFloat,
        translation: CGSize,
        systemBackGestureEdgeWidth: CGFloat
    ) {
        guard isExpanded, !isHandleDragActive else { return }
        guard startX > systemBackGestureEdgeWidth else { return }

        let verticalMovement = abs(translation.height)
        let horizontalMovement = abs(translation.width)
        let isDownwardDrag = translation.height > 0
        let isMostlyVertical = verticalMovement > horizontalMovement * PostCommentsSheetMetrics.verticalDragBias

        guard isDownwardDrag, isMostlyVertical else { return }
        if !isTrackingDrag {
            isTrackingDrag = true
            dragStartAllowsSheetDrag = true
            suppressesCollapsedUpvote = true
        }
        dragTranslation = max(0, translation.height)
    }

    mutating func canEndExpandedToolbarDrag() -> Bool {
        guard isTrackingDrag, dragStartAllowsSheetDrag else {
            resetDragTracking()
            return false
        }
        return true
    }

    func targetState(
        forPredictedTranslation predictedTranslation: CGFloat,
        expandedTop: CGFloat,
        collapsedTop: CGFloat
    ) -> SheetState {
        let baseTop = isExpanded ? expandedTop : collapsedTop
        let predictedTop = baseTop + predictedTranslation
        let midpoint = (expandedTop + collapsedTop) / 2
        return predictedTop <= midpoint ? .expanded : .collapsed
    }

    mutating func settle(
        predictedTranslation: CGFloat,
        expandedTop: CGFloat,
        collapsedTop: CGFloat
    ) {
        sheetState = targetState(
            forPredictedTranslation: predictedTranslation,
            expandedTop: expandedTop,
            collapsedTop: collapsedTop
        )
        dragTranslation = 0
        isTrackingDrag = false
        dragStartAllowsSheetDrag = false
        scrollDragStartedFromSettledTop = false
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
    let containerSize: CGSize
    let commentsViewport: CGRect
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
        containerSize: CGSize,
        commentsHorizontalInsets: (leading: CGFloat, trailing: CGFloat),
        collapsedHeight: CGFloat,
        controlsHeight: CGFloat,
        dragTranslation: CGFloat,
        isExpanded: Bool,
        expandedCommentsTopInset: (CGFloat) -> CGFloat
    ) {
        self.containerSize = containerSize
        commentsViewport = CGRect(
            x: commentsHorizontalInsets.leading,
            y: 0,
            width: max(
                containerSize.width - commentsHorizontalInsets.leading - commentsHorizontalInsets.trailing,
                0
            ),
            height: containerSize.height
        )
        expandedTop = 0
        collapsedTop = max(containerSize.height - (collapsedHeight + safeInsets.bottom), expandedTop)

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
        self.expandedCommentsTopInset = expandedCommentsTopInset(safeInsets.top)
        contentFadeProgress = min(max(expansionProgress, 0), 1)
    }
}

/// A settle animation that starts at the drag gesture's release velocity: the
/// SwiftUI analog of UIKit's
/// `UIView.animate(...usingSpringWithDamping:initialSpringVelocity:)`, which
/// cannot drive this SwiftUI-owned layout directly. The sheet keeps the
/// finger's speed through the release instead of restarting from rest, then
/// glides the rest of the way on a critically damped spring (no overshoot).
struct SheetSettleAnimation: CustomAnimation {
    static let defaultStiffness: CGFloat = 32
    static let maximumDuration: TimeInterval = 0.4

    /// Release velocity in progress units per second, normalized against the
    /// remaining travel and clamped to `stiffness`, the threshold past which
    /// a critically damped spring would overshoot its resting position.
    private let initialVelocity: CGFloat
    private let stiffness: CGFloat

    /// - Parameters:
    ///   - velocity: Release velocity along the sheet's vertical axis in
    ///     points per second (positive drives the sheet downward).
    ///   - distance: Signed distance from the release position to the settle
    ///     target in points (positive when the target is below).
    init(velocity: CGFloat, distance: CGFloat, stiffness: CGFloat = Self.defaultStiffness) {
        self.stiffness = stiffness
        var normalizedVelocity: CGFloat = 0
        if abs(distance) > 0.5 {
            normalizedVelocity = min(max(velocity / distance, 0), stiffness)
            if !normalizedVelocity.isFinite {
                normalizedVelocity = 0
            }
        }
        initialVelocity = normalizedVelocity
    }

    var duration: TimeInterval {
        Self.maximumDuration
    }

    func animate<V: VectorArithmetic>(
        value: V,
        time: TimeInterval,
        context: inout AnimationContext<V>
    ) -> V? {
        guard time >= 0, time < duration else { return nil }
        let progress = Self.progress(
            at: time,
            stiffness: stiffness,
            initialVelocity: initialVelocity
        )
        var scaledValue = value
        scaledValue.scale(by: progress)
        return scaledValue
    }

    /// Closed-form critically damped spring:
    /// `x(t) = 1 - (1 + (ω - v₀)·t)·e^(-ωt)` with `x(0) = 0`, `x'(0) = v₀`.
    static func progress(
        at time: TimeInterval,
        stiffness: CGFloat,
        initialVelocity: CGFloat
    ) -> CGFloat {
        let elapsed = CGFloat(time)
        return 1 - (1 + (stiffness - initialVelocity) * elapsed) * exp(-stiffness * elapsed)
    }
}
