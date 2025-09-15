//
//  LoadingStateManager.swift
//  Shared
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Foundation

@Observable
public final class LoadingStateManager<T>: @unchecked Sendable {
    public var data: T
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var hasAttemptedLoad = false

    private var loadData: (() async throws -> T)?
    private var shouldSkipLoad: ((T) -> Bool)?

    public init(
        initialData: T,
        shouldSkipLoad: @escaping (T) -> Bool = { _ in false },
        loadData: @escaping () async throws -> T,
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
        shouldSkipLoad: @escaping (T) -> Bool = { _ in false },
        loadData: @escaping () async throws -> T,
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

        isLoading = true
        error = nil

        do {
            data = try await loadData()
            hasAttemptedLoad = true
            isLoading = false
        } catch {
            self.error = error
            hasAttemptedLoad = true
            isLoading = false
        }
    }

    @MainActor
    public func reset() {
        hasAttemptedLoad = false
        error = nil
    }
}
