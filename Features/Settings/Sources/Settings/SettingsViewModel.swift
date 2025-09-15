//
//  SettingsViewModel.swift
//  Settings
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Combine
import Domain
import Foundation
import Shared

public final class SettingsViewModel: ObservableObject, @unchecked Sendable {
    private var settingsUseCase: any SettingsUseCase

    @Published public var safariReaderMode: Bool = false
    @Published public var openInDefaultBrowser: Bool = false
    @Published public var textSize: TextSize = .medium
    @Published public var cacheUsageText: String = "Calculating…"

    public init(settingsUseCase: any SettingsUseCase = DependencyContainer.shared.getSettingsUseCase()) {
        self.settingsUseCase = settingsUseCase
        loadSettings()
        refreshCacheUsage()
    }

    private func loadSettings() {
        safariReaderMode = settingsUseCase.safariReaderMode
        openInDefaultBrowser = settingsUseCase.openInDefaultBrowser
        textSize = settingsUseCase.textSize

        // Set up observers for changes
        setupBindings()
    }

    private func setupBindings() {
        // Use combine to sync changes back to the use case
        $safariReaderMode
            .dropFirst()
            .sink { [weak self] newValue in
                self?.settingsUseCase.safariReaderMode = newValue
            }
            .store(in: &cancellables)

        $openInDefaultBrowser
            .dropFirst()
            .sink { [weak self] newValue in
                self?.settingsUseCase.openInDefaultBrowser = newValue
            }
            .store(in: &cancellables)

        $textSize
            .dropFirst()
            .sink { [weak self] newValue in
                self?.settingsUseCase.textSize = newValue
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // User actions
    public func clearCache() {
        settingsUseCase.clearCache()
        refreshCacheUsage()
    }

    public func refreshCacheUsage() {
        Task { [weak self] in
            guard let self else { return }
            let bytes = await settingsUseCase.cacheUsageBytes()
            let formatted = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
            await MainActor.run { self.cacheUsageText = formatted }
        }
    }
}
