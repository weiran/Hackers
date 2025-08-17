import Foundation
import Domain
import Shared

@Observable
public final class SettingsViewModel: @unchecked Sendable {
    private var settingsUseCase: any SettingsUseCase

    public init(settingsUseCase: any SettingsUseCase = DependencyContainer.shared.getSettingsUseCase()) {
        self.settingsUseCase = settingsUseCase
    }

    public var safariReaderMode: Bool {
        get { settingsUseCase.safariReaderMode }
        set { settingsUseCase.safariReaderMode = newValue }
    }

    public var showThumbnails: Bool {
        get { settingsUseCase.showThumbnails }
        set { settingsUseCase.showThumbnails = newValue }
    }

    public var swipeActions: Bool {
        get { settingsUseCase.swipeActions }
        set { settingsUseCase.swipeActions = newValue }
    }

    public var showComments: Bool {
        get { settingsUseCase.showComments }
        set { settingsUseCase.showComments = newValue }
    }

    public var openInDefaultBrowser: Bool {
        get { settingsUseCase.openInDefaultBrowser }
        set { settingsUseCase.openInDefaultBrowser = newValue }
    }
}
