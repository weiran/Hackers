//
//  CleanSettingsViewWrapper.swift
//  Hackers
//
//  Wrapper to integrate the clean architecture Settings module
//

import SwiftUI
import Settings

struct CleanSettingsViewWrapper: View {
    var body: some View {
        // Using the new clean architecture CleanSettingsView from the Settings module
        CleanSettingsView()
    }
}