//
//  ReadStatusRepository.swift
//  Data
//
//  Provides an iCloud-synchronised implementation of post read state.
//

import Domain
import Foundation

public final class ReadStatusRepository: ReadStatusUseCase, @unchecked Sendable {
    private enum Constants {
        static let readPostsKey = "ReadStatus.posts"
        static let maximumEntries = 5_000
    }

    private let store: UbiquitousKeyValueStoreProtocol
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let now: () -> Date

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
        let entries = loadEntries()
        return Set(entries.map(\.id))
    }

    public func markPostRead(id: Int) async {
        var entries = loadEntries()
        entries.removeAll { $0.id == id }
        entries.insert(ReadStatusEntry(id: id, readAt: now()), at: 0)
        entries = Array(entries.sorted { $0.readAt > $1.readAt }.prefix(Constants.maximumEntries))
        persist(entries)
    }
}

private extension ReadStatusRepository {
    func loadEntries() -> [ReadStatusEntry] {
        _ = store.synchronize()
        guard let data = store.data(forKey: Constants.readPostsKey) else {
            return []
        }

        guard let entries = try? decoder.decode([ReadStatusEntry].self, from: data) else {
            return []
        }

        return entries.sorted { $0.readAt > $1.readAt }
    }

    func persist(_ entries: [ReadStatusEntry]) {
        guard let data = try? encoder.encode(entries) else { return }
        store.set(data, forKey: Constants.readPostsKey)
        _ = store.synchronize()
    }
}

private struct ReadStatusEntry: Codable, Sendable {
    let id: Int
    let readAt: Date
}
