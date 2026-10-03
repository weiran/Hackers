//
//  LoadingStateManagerTests.swift
//  SharedTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

@testable import Shared
import Foundation
import Testing

private actor LoadCounter {
    private var value = 0

    func increment() -> Int {
        value += 1
        return value
    }

    func current() -> Int {
        value
    }
}

@MainActor
@Suite("LoadingStateManager Tests")
struct LoadingStateManagerTests {
    @Test("loadIfNeeded loads data on first call")
    func loadIfNeededFirstCall() async {
        let loadCounter = LoadCounter()

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                _ = await loadCounter.increment()
                return ["item1", "item2"]
            },
        )

        await manager.loadIfNeeded()

        let loadCount = await loadCounter.current()
        #expect(loadCount == 1)
        #expect(manager.data == ["item1", "item2"])
        #expect(manager.hasAttemptedLoad == true)
        #expect(manager.isLoading == false)
        #expect(manager.error == nil)
    }

    @Test("loadIfNeeded skips loading when shouldSkipLoad returns true")
    func loadIfNeededSkipsWhenDataExists() async {
        let loadCounter = LoadCounter()

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                let count = await loadCounter.increment()
                return ["item\(count)"]
            },
        )

        // First load should work
        await manager.loadIfNeeded()
        let countAfterFirstLoad = await loadCounter.current()
        #expect(countAfterFirstLoad == 1)
        #expect(manager.data == ["item1"])

        // Second load should be skipped because data is not empty
        await manager.loadIfNeeded()
        let countAfterSecondLoad = await loadCounter.current()
        #expect(countAfterSecondLoad == 1) // Should still be 1, not incremented
        #expect(manager.data == ["item1"]) // Should remain the same
    }

    @Test("refresh always loads new data")
    func refreshAlwaysLoads() async {
        let loadCounter = LoadCounter()

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                let count = await loadCounter.increment()
                return ["refresh_item\(count)"]
            },
        )

        // Initial load
        await manager.loadIfNeeded()
        let countAfterFirstLoad = await loadCounter.current()
        #expect(countAfterFirstLoad == 1)
        #expect(manager.data == ["refresh_item1"])

        // Refresh should load even though data exists
        await manager.refresh()
        let countAfterFirstRefresh = await loadCounter.current()
        #expect(countAfterFirstRefresh == 2)
        #expect(manager.data == ["refresh_item2"])

        // Another refresh should also load
        await manager.refresh()
        let countAfterSecondRefresh = await loadCounter.current()
        #expect(countAfterSecondRefresh == 3)
        #expect(manager.data == ["refresh_item3"])
    }

    @Test("Error handling works correctly")
    func errorHandling() async {
        struct TestError: Error, Equatable {}

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                throw TestError()
            },
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
            },
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
    func concurrentLoadIfNeeded() async {
        let loadCounter = LoadCounter()

        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: {
                let count = await loadCounter.increment()
                // Simulate some async work
                try await Task.sleep(for: .milliseconds(10))
                return ["concurrent_item\(count)"]
            },
        )

        // Start multiple concurrent loads
        async let load1: Void = manager.loadIfNeeded()
        async let load2: Void = manager.loadIfNeeded()
        async let load3: Void = manager.loadIfNeeded()

        await load1
        await load2
        await load3

        // Only one load should have occurred
        let loadCount = await loadCounter.current()
        #expect(loadCount == 1)
        #expect(manager.data == ["concurrent_item1"])
    }

    @Test("A refresh supersedes an in-flight load")
    func refreshSupersedesInFlightLoad() async {
        let loadCounter = LoadCounter()
        let manager = LoadingStateManager(
            initialData: [] as [String],
            loadData: {
                let count = await loadCounter.increment()
                try await Task.sleep(for: count == 1 ? .milliseconds(100) : .milliseconds(10))
                return ["item\(count)"]
            }
        )

        let firstLoad = Task { await manager.loadIfNeeded() }
        try? await Task.sleep(for: .milliseconds(10))
        await manager.refresh()
        await firstLoad.value

        #expect(manager.data == ["item2"])
        #expect(manager.isLoading == false)
    }

}

private actor CancellationAwareLoadGate {
    private let cancellationError: Error
    private var started = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var continuation: CheckedContinuation<[String], Error>?
    private var cancellationHandled = false
    private var cancellationWaiter: CheckedContinuation<Void, Never>?

    init(cancellationError: Error) {
        self.cancellationError = cancellationError
    }

    func load() async throws -> [String] {
        started = true
        startWaiter?.resume()
        startWaiter = nil
        return try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                if Task.isCancelled {
                    handleCancellation()
                }
            }
        }, onCancel: {
            Task { await self.handleCancellation() }
        })
    }

    func waitUntilStarted() async {
        if started { return }
        await withCheckedContinuation { continuation in
            startWaiter = continuation
        }
    }

    private func handleCancellation() {
        guard !cancellationHandled else { return }
        cancellationHandled = true
        continuation?.resume(throwing: cancellationError)
        continuation = nil
        cancellationWaiter?.resume()
        cancellationWaiter = nil
    }

    func waitUntilCancellationHandled() async {
        if cancellationHandled { return }
        await withCheckedContinuation { continuation in
            cancellationWaiter = continuation
        }
    }
}



extension LoadingStateManagerTests {
    @Test("Cancellation abandons a gated load without consuming an attempt")
    func cancellationAbandonsLoad() async {
        let gate = CancellationAwareLoadGate(cancellationError: CancellationError())
        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: { try await gate.load() }
        )

        let loadTask = Task { await manager.refresh() }
        await gate.waitUntilStarted()
        loadTask.cancel()
        await gate.waitUntilCancellationHandled()
        await loadTask.value

        #expect(manager.error == nil)
        #expect(manager.hasAttemptedLoad == false)
        #expect(manager.isLoading == false)
    }

    @Test("A cancelled network load is treated as abandonment")
    func cancelledNetworkLoadAbandonsLoad() async {
        let gate = CancellationAwareLoadGate(cancellationError: URLError(.cancelled))
        let manager = LoadingStateManager(
            initialData: [] as [String],
            shouldSkipLoad: { !$0.isEmpty },
            loadData: { try await gate.load() }
        )

        let loadTask = Task { await manager.refresh() }
        await gate.waitUntilStarted()
        loadTask.cancel()
        await gate.waitUntilCancellationHandled()
        await loadTask.value

        #expect(manager.error == nil)
        #expect(manager.hasAttemptedLoad == false)
        #expect(manager.isLoading == false)
    }
}
