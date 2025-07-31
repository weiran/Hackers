import SwiftUI

class SettingsStore: ObservableObject {
    @Published var safariReaderMode = UserDefaults.standard.safariReaderModeEnabled {
        didSet {
            UserDefaults.standard.setSafariReaderMode(safariReaderMode)
        }
    }
    @Published var showThumbnails = UserDefaults.standard.showThumbnails {
        didSet {
            UserDefaults.standard.setShowThumbnails(showThumbnails)
            NotificationCenter.default.post(name: Notification.Name.refreshRequired, object: nil)
        }
    }
    @Published var swipeActions = UserDefaults.standard.swipeActionsEnabled {
        didSet {
            UserDefaults.standard.setSwipeActions(swipeActions)
            NotificationCenter.default.post(name: Notification.Name.refreshRequired, object: nil)
        }
    }
    @Published var showComments = UserDefaults.standard.showCommentsButton {
        didSet {
            UserDefaults.standard.setShowCommentsButton(showComments)
        }
    }
    @Published var openInDefaultBrowser = UserDefaults.standard.openInDefaultBrowser {
        didSet {
            UserDefaults.standard.setOpenInDefaultBrowser(openInDefaultBrowser)
        }
    }
}