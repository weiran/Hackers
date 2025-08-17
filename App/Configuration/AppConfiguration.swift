//
//  AppConfiguration.swift
//  Hackers
//
//  Configuration for enabling clean architecture migration
//

import Foundation

struct AppConfiguration {
    static let shared = AppConfiguration()
    
    // Feature flags for clean architecture migration
    // Set to true once the modules are added to Xcode project
    let useCleanFeed = false
    let useCleanSettings = true
    let useCleanComments = false // Not migrated yet
    
    private init() {}
}
