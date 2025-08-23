//
//  SettingsViewModel.swift
//  Settings
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import Combine
import Domain
import Shared

public final class SettingsViewModel: ObservableObject, @unchecked Sendable {
    private var settingsUseCase: any SettingsUseCase
    
    @Published public var safariReaderMode: Bool = false
    @Published public var showComments: Bool = false
    @Published public var openInDefaultBrowser: Bool = false
    @Published public var textSize: TextSize = .medium

    public init(settingsUseCase: any SettingsUseCase = DependencyContainer.shared.getSettingsUseCase()) {
        self.settingsUseCase = settingsUseCase
        loadSettings()
    }
    
    private func loadSettings() {
        safariReaderMode = settingsUseCase.safariReaderMode
        showComments = settingsUseCase.showComments
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
        
        $showComments
            .dropFirst()
            .sink { [weak self] newValue in
                self?.settingsUseCase.showComments = newValue
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
}
