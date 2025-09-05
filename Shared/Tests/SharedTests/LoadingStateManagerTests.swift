//
//  LoadingStateManagerTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Testing
@testable import Shared

@Suite("LoadingStateManager Tests")
struct LoadingStateManagerTests {

    @Test("Initial state is correct")
    func testInitialState() {
        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: { ["test"] }
        )

        #expect(manager.data == [])
        #expect(manager.isLoading == false)
        #expect(manager.error == nil)
        #expect(manager.hasAttemptedLoad == false)
    }

    @Test("loadIfNeeded loads data on first call")
    func testLoadIfNeededFirstCall() async {
        var loadCount = 0

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                loadCount += 1
                return ["item1", "item2"]
            }
        )

        await manager.loadIfNeeded()

        #expect(loadCount == 1)
        #expect(manager.data == ["item1", "item2"])
        #expect(manager.hasAttemptedLoad == true)
        #expect(manager.isLoading == false)
        #expect(manager.error == nil)
    }

    @Test("loadIfNeeded skips loading when shouldSkipLoad returns true")
    func testLoadIfNeededSkipsWhenDataExists() async {
        var loadCount = 0

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                loadCount += 1
                return ["item\(loadCount)"]
            }
        )

        // First load should work
        await manager.loadIfNeeded()
        #expect(loadCount == 1)
        #expect(manager.data == ["item1"])

        // Second load should be skipped because data is not empty
        await manager.loadIfNeeded()
        #expect(loadCount == 1) // Should still be 1, not incremented
        #expect(manager.data == ["item1"]) // Should remain the same
    }

    @Test("refresh always loads new data")
    func testRefreshAlwaysLoads() async {
        var loadCount = 0

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                loadCount += 1
                return ["refresh_item\(loadCount)"]
            }
        )

        // Initial load
        await manager.loadIfNeeded()
        #expect(loadCount == 1)
        #expect(manager.data == ["refresh_item1"])

        // Refresh should load even though data exists
        await manager.refresh()
        #expect(loadCount == 2)
        #expect(manager.data == ["refresh_item2"])

        // Another refresh should also load
        await manager.refresh()
        #expect(loadCount == 3)
        #expect(manager.data == ["refresh_item3"])
    }

    @Test("Error handling works correctly")
    func testErrorHandling() async {
        struct TestError: Error, Equatable {}

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                throw TestError()
            }
        )

        await manager.loadIfNeeded()

        #expect(manager.data == []) // Should remain empty
        #expect(manager.hasAttemptedLoad == true) // Should mark as attempted
        #expect(manager.isLoading == false) // Should not be loading
        #expect(manager.error != nil) // Should have an error
        #expect(manager.error is TestError)
    }

    @Test("reset clears attempt flag and error")
    func testReset() async {
        struct TestError: Error {}

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                throw TestError()
            }
        )

        // Load and fail
        await manager.loadIfNeeded()
        #expect(manager.hasAttemptedLoad == true)
        #expect(manager.error != nil)

        // Reset
        await manager.reset()
        #expect(manager.hasAttemptedLoad == false)
        #expect(manager.error == nil)
    }

    @Test("Concurrent loadIfNeeded calls don't cause multiple loads")
    func testConcurrentLoadIfNeeded() async {
        var loadCount = 0

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                loadCount += 1
                // Simulate some async work
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
                return ["concurrent_item\(loadCount)"]
            }
        )

        // Start multiple concurrent loads
        async let load1: Void = manager.loadIfNeeded()
        async let load2: Void = manager.loadIfNeeded()
        async let load3: Void = manager.loadIfNeeded()

        await load1
        await load2
        await load3

        // Only one load should have occurred
        #expect(loadCount == 1)
        #expect(manager.data == ["concurrent_item1"])
    }

    @Test("loadIfNeeded with custom shouldSkipLoad logic")
    func testCustomShouldSkipLogic() async {
        var loadCount = 0

        // Skip loading if we have more than 2 items
        let manager = LoadingStateManager(
            initialData: ["initial"] as [String],
            shouldSkipLoad: { $0.count > 2 },
            loadData: {
                loadCount += 1
                return manager.data + ["new_item\(loadCount)"]
            }
        )

        // First load: [initial] -> [initial, new_item1] (count = 2, should not skip)
        await manager.loadIfNeeded()
        #expect(loadCount == 1)
        #expect(manager.data == ["initial", "new_item1"])

        // Second load: [initial, new_item1] -> [initial, new_item1, new_item2] (count = 3, should skip next time)
        await manager.loadIfNeeded()
        #expect(loadCount == 2)
        #expect(manager.data == ["initial", "new_item1", "new_item2"])

        // Third load: count > 2, should skip
        await manager.loadIfNeeded()
        #expect(loadCount == 2) // Should not increment
        #expect(manager.data == ["initial", "new_item1", "new_item2"]) // Should not change
    }

    @Test("Initialization with minimal parameters")
    func testMinimalInitialization() async {
        let manager = LoadingStateManager(initialData: ["test"])

        #expect(manager.data == ["test"])
        #expect(manager.isLoading == false)
        #expect(manager.error == nil)
        #expect(manager.hasAttemptedLoad == false)

        // loadIfNeeded should do nothing without load function
        await manager.loadIfNeeded()
        #expect(manager.data == ["test"]) // Should remain unchanged
    }

    @Test("setLoadFunction configures loading behavior")
    func testSetLoadFunction() async {
        var loadCount = 0

        let manager = LoadingStateManager(initialData: [] as [String])

        // Initially, loadIfNeeded should do nothing
        await manager.loadIfNeeded()
        #expect(manager.data == [])

        // Set load function
        manager.setLoadFunction(
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                loadCount += 1
                return ["configured_item\(loadCount)"]
            }
        )

        // Now loadIfNeeded should work
        await manager.loadIfNeeded()
        #expect(loadCount == 1)
        #expect(manager.data == ["configured_item1"])
    }
}
