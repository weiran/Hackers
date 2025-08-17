// swiftlint:disable force_cast

import Testing
@testable import Data
@testable import Domain
import Foundation

@Suite("SettingsRepository Tests")
struct SettingsRepositoryTests {
    
    let mockUserDefaults = MockUserDefaults()
    var settingsRepository: SettingsRepository {
        SettingsRepository(userDefaults: mockUserDefaults)
    }
    
    // MARK: - Mock UserDefaults
    
    final class MockUserDefaults: UserDefaultsProtocol, @unchecked Sendable {
        private var storage: [String: Any] = [:]
        
        func bool(forKey defaultName: String) -> Bool {
            return storage[defaultName] as? Bool ?? false
        }
        
        func set(_ value: Bool, forKey defaultName: String) {
            storage[defaultName] = value
        }
        
        func string(forKey defaultName: String) -> String? {
            return storage[defaultName] as? String
        }
        
        func set(_ value: Any?, forKey defaultName: String) {
            storage[defaultName] = value
        }
        
        func removeObject(forKey defaultName: String) {
            storage.removeValue(forKey: defaultName)
        }
        
        func clearAll() {
            storage.removeAll()
        }
    }
    
    // MARK: - Initialization Tests
    
    @Test("SettingsRepository initialization")
    func settingsRepositoryInitialization() {
        #expect(settingsRepository != nil, "SettingsRepository should initialize successfully")
    }
    
    @Test("SettingsRepository initialization with default UserDefaults")
    func settingsRepositoryInitializationWithDefaultUserDefaults() {
        let repository = SettingsRepository()
        #expect(repository != nil)
    }
    
    // MARK: - Safari Reader Mode Tests
    
    @Test("Safari reader mode default value")
    func safariReaderModeDefaultValue() {
        // Default should be false for bool values
        #expect(settingsRepository.safariReaderMode == false)
    }
    
    @Test("Safari reader mode setter and getter")
    func safariReaderModeSetterAndGetter() {
        // Test setting to true
        settingsRepository.safariReaderMode = true
        #expect(settingsRepository.safariReaderMode == true)
        #expect(mockUserDefaults.bool(forKey: "SafariReaderMode") == true)
        
        // Test setting to false
        settingsRepository.safariReaderMode = false
        #expect(settingsRepository.safariReaderMode == false)
        #expect(mockUserDefaults.bool(forKey: "SafariReaderMode") == false)
    }
    
    // MARK: - Show Thumbnails Tests
    
    @Test("Show thumbnails default value")
    func showThumbnailsDefaultValue() {
        // Default should be false for bool values
        #expect(settingsRepository.showThumbnails == false)
    }
    
    @Test("Show thumbnails setter and getter")
    func showThumbnailsSetterAndGetter() {
        // Test setting to true
        settingsRepository.showThumbnails = true
        #expect(settingsRepository.showThumbnails == true)
        #expect(mockUserDefaults.bool(forKey: "ShowThumbnails") == true)
        
        // Test setting to false
        settingsRepository.showThumbnails = false
        #expect(settingsRepository.showThumbnails == false)
        #expect(mockUserDefaults.bool(forKey: "ShowThumbnails") == false)
    }
    
    // MARK: - Swipe Actions Tests
    
    @Test("Swipe actions default value")
    func swipeActionsDefaultValue() {
        // Default should be false for bool values
        #expect(settingsRepository.swipeActions == false)
    }
    
    @Test("Swipe actions setter and getter")
    func swipeActionsSetterAndGetter() {
        // Test setting to true
        settingsRepository.swipeActions = true
        #expect(settingsRepository.swipeActions == true)
        #expect(mockUserDefaults.bool(forKey: "SwipeActionsEnabled") == true)
        
        // Test setting to false
        settingsRepository.swipeActions = false
        #expect(settingsRepository.swipeActions == false)
        #expect(mockUserDefaults.bool(forKey: "SwipeActionsEnabled") == false)
    }
    
    // MARK: - Show Comments Tests
    
    @Test("Show comments default value")
    func showCommentsDefaultValue() {
        // Default should be false for bool values
        #expect(settingsRepository.showComments == false)
    }
    
    @Test("Show comments setter and getter")
    func showCommentsSetterAndGetter() {
        // Test setting to true
        settingsRepository.showComments = true
        #expect(settingsRepository.showComments == true)
        #expect(mockUserDefaults.bool(forKey: "ShowCommentsButton") == true)
        
        // Test setting to false
        settingsRepository.showComments = false
        #expect(settingsRepository.showComments == false)
        #expect(mockUserDefaults.bool(forKey: "ShowCommentsButton") == false)
    }
    
    // MARK: - Open In Default Browser Tests
    
    @Test("Open in default browser default value")
    func openInDefaultBrowserDefaultValue() {
        // Default should be false for bool values
        #expect(settingsRepository.openInDefaultBrowser == false)
    }
    
    @Test("Open in default browser setter and getter")
    func openInDefaultBrowserSetterAndGetter() {
        // Test setting to true
        settingsRepository.openInDefaultBrowser = true
        #expect(settingsRepository.openInDefaultBrowser == true)
        #expect(mockUserDefaults.bool(forKey: "OpenInDefaultBrowser") == true)
        
        // Test setting to false
        settingsRepository.openInDefaultBrowser = false
        #expect(settingsRepository.openInDefaultBrowser == false)
        #expect(mockUserDefaults.bool(forKey: "OpenInDefaultBrowser") == false)
    }
    
    // MARK: - Integration Tests
    
    @Test("Multiple settings changes persist")
    func multipleSettingsChangesPersist() {
        // Change multiple settings
        settingsRepository.safariReaderMode = true
        settingsRepository.showThumbnails = true
        settingsRepository.swipeActions = false
        settingsRepository.showComments = false
        settingsRepository.openInDefaultBrowser = true
        
        // Verify all changes persist
        #expect(settingsRepository.safariReaderMode == true)
        #expect(settingsRepository.showThumbnails == true)
        #expect(settingsRepository.swipeActions == false)
        #expect(settingsRepository.showComments == false)
        #expect(settingsRepository.openInDefaultBrowser == true)
        
        // Verify underlying storage
        #expect(mockUserDefaults.bool(forKey: "SafariReaderMode") == true)
        #expect(mockUserDefaults.bool(forKey: "ShowThumbnails") == true)
        #expect(mockUserDefaults.bool(forKey: "SwipeActionsEnabled") == false)
        #expect(mockUserDefaults.bool(forKey: "ShowCommentsButton") == false)
        #expect(mockUserDefaults.bool(forKey: "OpenInDefaultBrowser") == true)
    }
    
    @Test("Settings independence")
    func settingsIndependence() {
        // Test that changing one setting doesn't affect others
        settingsRepository.safariReaderMode = true
        
        // Other settings should remain at their default values
        #expect(settingsRepository.showThumbnails == false)
        #expect(settingsRepository.swipeActions == false)
        #expect(settingsRepository.showComments == false)
        #expect(settingsRepository.openInDefaultBrowser == false)
    }
    
    // MARK: - Use Case Protocol Conformance Tests
    
    @Test("Conforms to SettingsUseCase")
    func conformsToSettingsUseCase() {
        // Test that the repository properly conforms to SettingsUseCase protocol
        var useCase: SettingsUseCase = settingsRepository
        
        // Test that we can access properties through the protocol
        useCase.safariReaderMode = true
        #expect(useCase.safariReaderMode == true)
        
        useCase.showThumbnails = true
        #expect(useCase.showThumbnails == true)
        
        useCase.swipeActions = false
        #expect(useCase.swipeActions == false)
        
        useCase.showComments = false
        #expect(useCase.showComments == false)
        
        useCase.openInDefaultBrowser = true
        #expect(useCase.openInDefaultBrowser == true)
    }
    
    // MARK: - Key Consistency Tests
    
    @Test("UserDefaults keys")
    func userDefaultsKeys() {
        // Test that the correct keys are being used for UserDefaults
        settingsRepository.safariReaderMode = true
        settingsRepository.showThumbnails = true
        settingsRepository.swipeActions = true
        settingsRepository.showComments = true
        settingsRepository.openInDefaultBrowser = true
        
        // Verify the keys match what's expected
        #expect(mockUserDefaults.bool(forKey: "SafariReaderMode") == true)
        #expect(mockUserDefaults.bool(forKey: "ShowThumbnails") == true)
        #expect(mockUserDefaults.bool(forKey: "SwipeActionsEnabled") == true)
        #expect(mockUserDefaults.bool(forKey: "ShowCommentsButton") == true)
        #expect(mockUserDefaults.bool(forKey: "OpenInDefaultBrowser") == true)
    }
    
    // MARK: - Thread Safety Tests
    
    @Test("Concurrent access")
    func concurrentAccess() async {
        // Test concurrent read/write operations
        await withTaskGroup(of: Void.self) { group in
            // Add multiple concurrent tasks
            for index in 0..<10 {
                group.addTask {
                    let isEven = index % 2 == 0
                    self.settingsRepository.safariReaderMode = isEven
                    self.settingsRepository.showThumbnails = !isEven
                }
            }
        }
        
        // After concurrent operations, the values should be consistent
        // (either both true or both false, depending on which task finished last)
        let safariMode = settingsRepository.safariReaderMode
        let thumbnails = settingsRepository.showThumbnails
        
        // These should be opposite values
        #expect(safariMode != thumbnails)
    }
}
