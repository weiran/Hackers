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

private final class MockReadStatusStore: UbiquitousKeyValueStoreProtocol, @unchecked Sendable {
    private var storage: [String: Any] = [:]

    func data(forKey defaultName: String) -> Data? {
        storage[defaultName] as? Data
    }

    func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }

    func synchronize() -> Bool { true }
}
