//
//  ReadStatusRepositoryTests.swift
//  DataTests
//

@testable import Data
import Foundation
import Testing

@Suite("ReadStatusRepository")
struct ReadStatusRepositoryTests {
    @Test("Read IDs persist after marking posts read")
    func readIDsPersist() async {
        let store = MockReadStatusStore()
        let repository = ReadStatusRepository(store: store, now: { Date(timeIntervalSince1970: 1_234) })

        await repository.markPostRead(id: 42)

        let ids = await repository.readPostIDs()
        #expect(ids == [42])

        let secondRepository = ReadStatusRepository(store: store)
        let reloadedIDs = await secondRepository.readPostIDs()
        #expect(reloadedIDs == [42])
    }

    @Test("Marking the same post read does not duplicate it")
    func duplicateMarksDoNotDuplicateIDs() async {
        let store = MockReadStatusStore()
        var currentTime: TimeInterval = 1
        let repository = ReadStatusRepository(store: store, now: {
            defer { currentTime += 1 }
            return Date(timeIntervalSince1970: currentTime)
        })

        await repository.markPostRead(id: 1)
        await repository.markPostRead(id: 2)
        await repository.markPostRead(id: 1)

        let ids = await repository.readPostIDs()
        #expect(ids == [1, 2])
    }

    @Test("Read status prunes oldest entries")
    func prunesOldestEntries() async {
        let store = MockReadStatusStore()
        var currentTime: TimeInterval = 1
        let repository = ReadStatusRepository(store: store, now: {
            defer { currentTime += 1 }
            return Date(timeIntervalSince1970: currentTime)
        })

        for id in 0 ... 5_000 {
            await repository.markPostRead(id: id)
        }

        let ids = await repository.readPostIDs()
        #expect(ids.count == 5_000)
        #expect(ids.contains(0) == false)
        #expect(ids.contains(5_000) == true)
    }
}

@Suite("ReadStatusRepository reliability")
struct ReadStatusRepositoryReliabilityTests {
    @Test("Local marks inspect persisted bytes and public reads refresh external state")
    func localMarksUseCacheAndPublicReadsRefresh() async {
        let store = MockReadStatusStore()
        let repository = ReadStatusRepository(store: store, now: { Date(timeIntervalSince1970: 1) })

        await repository.markPostRead(id: 1)
        await repository.markPostRead(id: 2)
        await repository.markPostRead(id: 3)
        #expect(store.dataReadCount == 3)

        store.setExternalEntries([99])
        let ids = await repository.readPostIDs()
        #expect(ids == [99])
        #expect(store.dataReadCount == 4)
    }

    @Test("Malformed read status bytes are not overwritten by a mark")
    func malformedReadStatusIsPreserved() async {
        let store = MockReadStatusStore()
        let corrupt = Data([0xde, 0xad, 0xbe, 0xef])
        store.set(corrupt, forKey: "ReadStatus.posts")
        let repository = ReadStatusRepository(store: store, now: { Date(timeIntervalSince1970: 1) })

        await repository.markPostRead(id: 42)

        #expect(store.data(forKey: "ReadStatus.posts") == corrupt)
    }

    @Test("A mark merges an external change received after the cache was loaded")
    func markObservesExternalChange() async {
        let store = MockReadStatusStore()
        let repository = ReadStatusRepository(store: store)
        await repository.markPostRead(id: 1)
        store.setExternalEntries([99])
        await repository.markPostRead(id: 2)
        #expect(await repository.readPostIDs() == [99, 2])
    }

    @Test("Corruption arriving after a valid cache is preserved until valid data returns")
    func corruptionAfterCacheIsPreserved() async {
        let store = MockReadStatusStore()
        let repository = ReadStatusRepository(store: store)
        await repository.markPostRead(id: 1)
        let corrupt = Data([0xde, 0xad])
        store.set(corrupt, forKey: "ReadStatus.posts")
        await repository.markPostRead(id: 2)
        #expect(store.data(forKey: "ReadStatus.posts") == corrupt)
        #expect(await repository.readPostIDs() == [1])
        store.setExternalEntries([99])
        await repository.markPostRead(id: 3)
        #expect(await repository.readPostIDs() == [99, 3])
    }

    @Test("Pruning respects timestamps when the local clock moves backwards")
    func pruningWithClockRegression() async {
        let store = MockReadStatusStore()
        store.setExternalEntries(Array(0..<5_000))
        let repository = ReadStatusRepository(store: store, now: { Date(timeIntervalSince1970: 0) })
        await repository.markPostRead(id: 9_999)
        let ids = await repository.readPostIDs()
        #expect(ids.count == 5_000)
        #expect(!ids.contains(9_999))
        #expect(ids.contains(0))
    }
}

private final class MockReadStatusStore: UbiquitousKeyValueStoreProtocol, @unchecked Sendable {
    private var storage: [String: Any] = [:]
    private(set) var dataReadCount = 0

    func data(forKey defaultName: String) -> Data? {
        dataReadCount += 1
        return storage[defaultName] as? Data
    }

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func synchronize() -> Bool { true }

    func setExternalEntries(_ ids: [Int]) {
        let formatter = ISO8601DateFormatter()
        let payload = ids.enumerated().map { index, id in
            [
                "id": id,
                "readAt": formatter.string(from: Date(timeIntervalSince1970: TimeInterval(index + 1)))
            ] as [String: Any]
        }
        storage["ReadStatus.posts"] = try? JSONSerialization.data(withJSONObject: payload)
    }
}
