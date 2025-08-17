import Foundation

public protocol SettingsUseCase: Sendable {
    var safariReaderMode: Bool { get set }
    var showThumbnails: Bool { get set }
    var swipeActions: Bool { get set }
    var showComments: Bool { get set }
    var openInDefaultBrowser: Bool { get set }
}