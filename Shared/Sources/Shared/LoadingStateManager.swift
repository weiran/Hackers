//
//  LoadingStateManager.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

@Observable
public final class LoadingStateManager<T: Sendable>: @unchecked Sendable {
    public var data: T
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var hasAttemptedLoad = false

    private var loadData: (@Sendable () async throws -> T)?
    private var shouldSkipLoad: (@Sendable (T) -> Bool)?

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
        guard !isLoading else { return }
        await performLoad()
    }

    @MainActor
    private func performLoad() async {
        guard let loadData else { return }
        let loader = loadData

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let result = try await Task.detached(priority: .userInitiated) {
                try await loader()
            }.value
            data = result
            hasAttemptedLoad = true
        } catch {
            self.error = error
            hasAttemptedLoad = true
        }
    }

    @MainActor
    public func reset() {
        hasAttemptedLoad = false
        error = nil
    }
}
