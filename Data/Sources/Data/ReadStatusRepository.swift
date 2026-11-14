//
//  ReadStatusRepository.swift
//  Data
//
//  Provides an iCloud-synchronised implementation of post read state.
//

import Domain
import Foundation

public actor ReadStatusRepository: ReadStatusUseCase {
    private enum Constants {
        static let readPostsKey = "ReadStatus.posts"
        static let maximumEntries = 5_000
    }

    private let store: UbiquitousKeyValueStoreProtocol
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let now: () -> Date
    private var cachedEntries: [ReadStatusEntry] = []
    private var hasLoadedCache = false
    private var cacheIsCorrupt = false
    private var cachedData: Data?

    public init(
        store: UbiquitousKeyValueStoreProtocol = NSUbiquitousKeyValueStore.default,
        now: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.now = now

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func readPostIDs() async -> Set<Int> {
        refreshCacheFromStore()
        return Set(cachedEntries.map(\.id))
    }

    public func markPostRead(id: Int) async {
        refreshCacheFromStore()
        // A malformed payload is not an empty history. Keep the raw bytes and
        // last known-good snapshot intact rather than replacing recoverable data.
        guard !cacheIsCorrupt else { return }

        cachedEntries.removeAll { $0.id == id }
        let entry = ReadStatusEntry(id: id, readAt: now())
        let index = cachedEntries.firstIndex { $0.readAt <= entry.readAt } ?? cachedEntries.endIndex
        cachedEntries.insert(entry, at: index)
        if cachedEntries.count > Constants.maximumEntries {
            cachedEntries.removeLast(cachedEntries.count - Constants.maximumEntries)
        }
        persist(cachedEntries)
    }
}

private extension ReadStatusRepository {
    func refreshCacheFromStore() {
        _ = store.synchronize()
        let data = store.data(forKey: Constants.readPostsKey)
        // Reuse decoded entries only while the actual store bytes are unchanged.
        // A notification can arrive after a local mutation, so it is not a write guard.
        guard !hasLoadedCache || data != cachedData else { return }
        cachedData = data
        guard let data else {
            cachedEntries = []
            hasLoadedCache = true
            cacheIsCorrupt = false
            return
        }

        guard let entries = try? decoder.decode([ReadStatusEntry].self, from: data) else {
            // Preserve any last-known-good in-memory state and refuse all local
            // writes until a valid external payload arrives.
            hasLoadedCache = true
            cacheIsCorrupt = true
            return
        }

        cachedEntries = entries.sorted { $0.readAt > $1.readAt }
        hasLoadedCache = true
        cacheIsCorrupt = false
    }

    func persist(_ entries: [ReadStatusEntry]) {
        guard let data = try? encoder.encode(entries) else { return }
        store.set(data, forKey: Constants.readPostsKey)
        cachedData = data
        _ = store.synchronize()
    }
}

private struct ReadStatusEntry: Codable, Sendable {
    let id: Int
    let readAt: Date
}
