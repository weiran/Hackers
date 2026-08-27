//
//  WhatsNewCoordinator.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Domain
import Foundation
import Feed
import WhatsNew
import SwiftUI

@MainActor
final class WhatsNewCoordinator {
    private let whatsNewUseCase: any WhatsNewUseCase
    private let appVersion: String

    init(whatsNewUseCase: any WhatsNewUseCase, appVersion: String = Bundle.main.shortVersionString) {
        self.whatsNewUseCase = whatsNewUseCase
        self.appVersion = appVersion
    }

    func shouldShowWhatsNew(forceShow: Bool = false) -> Bool {
        whatsNewUseCase.shouldShowWhatsNew(currentVersion: appVersion, forceShow: forceShow)
    }

    func markWhatsNewShown() {
        whatsNewUseCase.markWhatsNewShown(for: appVersion)
    }

    func makeWhatsNewPanel(
        onOpen: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> WhatsNewPanel {
        WhatsNewPanel(
            title: WhatsNewService.currentTitle(),
            action: onOpen,
            dismissAction: onDismiss
        )
    }

    func makeWhatsNewView(onDismiss: @escaping () -> Void) -> some View {
        WhatsNew.WhatsNewService.createWhatsNewView {
            self.markWhatsNewShown()
            onDismiss()
        }
    }
}

private extension Bundle {
    var shortVersionString: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }
}
