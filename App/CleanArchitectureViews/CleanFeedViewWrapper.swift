//
//  CleanFeedViewWrapper.swift
//  Hackers
//
//  Wrapper to integrate the clean architecture Feed module
//

import SwiftUI
// The Feed module would be imported here once added to Xcode project
// import Feed

// Temporary wrapper until Feed module is properly integrated into Xcode
struct CleanFeedViewWrapper: View {
    @EnvironmentObject private var navigationStore: NavigationStore
    let isSidebar: Bool

    init(isSidebar: Bool = false) {
        self.isSidebar = isSidebar
    }

    var body: some View {
        // This will be replaced with the actual CleanFeedView from the Feed module
        // For now, we'll use the existing FeedView
        FeedView(isSidebar: isSidebar)
            .environmentObject(navigationStore)
    }
}
