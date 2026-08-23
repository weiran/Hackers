//
//  LoadingStateManager.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
public final class LoadingStateManager<T: Sendable>: @unchecked Sendable {
    public var data: T
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var hasAttemptedLoad = false

    private var loadData: (@Sendable () async throws -> T)?
    private var shouldSkipLoad: (@Sendable (T) -> Bool)?
    private var loadGeneration = 0

    public init(
        initialData: T,
        shouldSkipLoad: @escaping @Sendable (T) -> Bool = { _ in false },
        loadData: @escaping @Sendable () async throws -> T,
    ) {
        data = initialData
        self.shouldSkipLoad = shouldSkipLoad
        self.loadData = loadData
    }

    public init(initialData: T) {
        data = initialData
        shouldSkipLoad = nil
        loadData = nil
    }

    public func setLoadFunction(
        shouldSkipLoad: @escaping @Sendable (T) -> Bool = { _ in false },
        loadData: @escaping @Sendable () async throws -> T,
    ) {
        self.shouldSkipLoad = shouldSkipLoad
        self.loadData = loadData
    }

    @MainActor
    public func loadIfNeeded() async {
        guard !isLoading else { return }
        guard let shouldSkipLoad else { return }
        guard !hasAttemptedLoad || !shouldSkipLoad(data) else { return }

        await performLoad()
    }

    @MainActor
    public func refresh() async {
        await performLoad()
    }

    @MainActor
    private func performLoad() async {
        guard let loadData else { return }
        let loader = loadData
        loadGeneration += 1
        let generation = loadGeneration

        isLoading = true
        error = nil

        do {
            let result = try await loader()
            guard generation == loadGeneration else { return }
            data = result
            hasAttemptedLoad = true
        } catch {
            guard generation == loadGeneration else { return }
            self.error = error
            hasAttemptedLoad = true
        }
        if generation == loadGeneration {
            isLoading = false
        }
    }

    @MainActor
    public func reset() {
        loadGeneration += 1
        isLoading = false
        hasAttemptedLoad = false
        error = nil
    }
}
