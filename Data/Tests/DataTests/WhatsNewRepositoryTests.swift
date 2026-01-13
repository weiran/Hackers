//
//  WhatsNewRepositoryTests.swift
//  DataTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Data
import Foundation
import Testing

@Suite("WhatsNewRepository")
struct WhatsNewRepositoryTests {
    @Test("Force show overrides stored state")
    func forceShowOverridesStoredState() {
        let store = MockStore(lastShownVersion: "5.1")
        let repository = WhatsNewRepository(versionStore: store, processArguments: [])
        #expect(repository.shouldShowWhatsNew(currentVersion: "5.2", forceShow: true))
    }

    @Test("Disable argument prevents whats new when not forced")
    func disableArgumentPreventsWhatsNew() {
        let repository = WhatsNewRepository(versionStore: MockStore(lastShownVersion: nil), processArguments: ["disableWhatsNew"])
        #expect(repository.shouldShowWhatsNew(currentVersion: "5.2", forceShow: false) == false)
    }

    @Test("Does not show for first-time installs")
    func doesNotShowForFirstTimeInstalls() {
        let store = MockStore(lastShownVersion: nil)
        let repository = WhatsNewRepository(versionStore: store, processArguments: [])
        #expect(repository.shouldShowWhatsNew(currentVersion: "5.2", forceShow: false) == false)
        #expect(store.lastShownVersion() == "5.2")
    }

    @Test("Patch updates do not retrigger onboarding")
    func patchUpdateDoesNotRetrigger() {
        let store = MockStore(lastShownVersion: "5.2.0")
        let repository = WhatsNewRepository(versionStore: store, processArguments: [])
        #expect(repository.shouldShowWhatsNew(currentVersion: "5.2.1", forceShow: false) == false)
    }

    @Test("Revision bump does not retrigger onboarding")
    func revisionBumpDoesNotRetrigger() {
        let store = MockStore(lastShownVersion: "5.2.1")
        let repository = WhatsNewRepository(versionStore: store, processArguments: [])
        #expect(repository.shouldShowWhatsNew(currentVersion: "5.2.2", forceShow: false) == false)
    }

    @Test("Minor updates retrigger onboarding once")
    func minorUpdateRetriggersOnce() {
        let store = MockStore(lastShownVersion: "5.1.2")
        let repository = WhatsNewRepository(versionStore: store, processArguments: [])
        #expect(repository.shouldShowWhatsNew(currentVersion: "5.2.0", forceShow: false))
    }

    @Test("Minor bump retriggers onboarding even without patch component")
    func minorBumpWithoutPatchComponentRetriggers() {
        let store = MockStore(lastShownVersion: "5.2.1")
        let repository = WhatsNewRepository(versionStore: store, processArguments: [])
        #expect(repository.shouldShowWhatsNew(currentVersion: "5.3", forceShow: false))
    }

    @Test("Major updates retrigger onboarding")
    func majorUpdateRetriggers() {
        let store = MockStore(lastShownVersion: "5.2.1")
        let repository = WhatsNewRepository(versionStore: store, processArguments: [])
        #expect(repository.shouldShowWhatsNew(currentVersion: "6.0.0", forceShow: false))
    }

    @Test("Falls back to string comparison for invalid versions")
    func fallsBackForInvalidVersions() {
        let store = MockStore(lastShownVersion: "beta")
        let repository = WhatsNewRepository(versionStore: store, processArguments: [])
        #expect(repository.shouldShowWhatsNew(currentVersion: "beta", forceShow: false) == false)
        #expect(repository.shouldShowWhatsNew(currentVersion: "rc1", forceShow: false))
    }

    @Test("Marks whats new as shown")
    func marksWhatsNewAsShown() {
        let store = MockStore(lastShownVersion: nil)
        let repository = WhatsNewRepository(versionStore: store, processArguments: [])
        repository.markWhatsNewShown(for: "5.2")
        #expect(store.lastShownVersion() == "5.2")
    }

    @Test("UserDefaults store defaults to false")
    func userDefaultsStoreDefaultsToFalse() {
        let defaults = makeIsolatedDefaults()
        let store = UserDefaultsWhatsNewVersionStore(userDefaults: defaults)
        #expect(store.lastShownVersion() == nil)
    }

    @Test("UserDefaults store records shown state")
    func userDefaultsStoreRecordsShownState() {
        let defaults = makeIsolatedDefaults()
        let store = UserDefaultsWhatsNewVersionStore(userDefaults: defaults)
        store.save(shownVersion: "5.2")
        #expect(store.lastShownVersion() == "5.2")
    }

    final class MockStore: WhatsNewVersionStore, @unchecked Sendable {
        private var storedVersion: String?
        init(lastShownVersion: String?) {
            storedVersion = lastShownVersion
        }

        func lastShownVersion() -> String? {
            storedVersion
        }

        func save(shownVersion: String) {
            storedVersion = shownVersion
        }
    }

    private func makeIsolatedDefaults() -> UserDefaults {
        let suiteName = "com.weiran.hackers.tests.whatsnew.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Expected to create user defaults for suite \(suiteName)")
        }
        defaults.removePersistentDomain(forName: suiteName)
        defaults.synchronize()
        return defaults
    }
}
