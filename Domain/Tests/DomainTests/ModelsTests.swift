@testable import Domain
import Foundation
import Testing

@Suite("Domain regression contracts")
struct ModelsTests {
    @Test("Comment value updates remain unequal for SwiftUI row diffing")
    func commentEqualityTracksContent() {
        let base = Comment(
            id: 456,
            age: "1 hour ago",
            text: "Test comment",
            by: "user",
            level: 0,
            upvoted: false
        )
        #expect(base != base.with(upvoted: true))
        #expect(base != base.withVisibility(.compact))
        #expect(base.hashValue == base.with(upvoted: true).hashValue)
    }

    @Test("Store product ordering and unknown identifiers match purchase lookup behavior")
    func supportProductMappingAndOrdering() {
        #expect(SupportProductIdentifier.supporterMonthly.kind == .subscription)
        #expect(SupportProductIdentifier.tipSmall.kind == .tip)
        #expect(SupportProductIdentifier.allCases.sorted { $0.sortOrder < $1.sortOrder } == [
            .supporterMonthly, .tipSmall, .tipMedium, .tipLarge
        ])
        #expect(SupportProductIdentifier(rawValue: "com.example.unknown") == nil)
    }
}
