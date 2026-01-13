//
//  WhatsNewService.swift
//  Hackers
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import SwiftUI

@MainActor
public enum WhatsNewService {
    public static func createWhatsNewView(
        onDismiss: @escaping () -> Void,
    ) -> some View {
        let whatsNewData = WhatsNewData.currentWhatsNew()
        return WhatsNewView(whatsNewData: whatsNewData, onDismiss: onDismiss)
    }
}
