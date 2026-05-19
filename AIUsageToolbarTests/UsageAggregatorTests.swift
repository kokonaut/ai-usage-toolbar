import XCTest

@testable import AIUsageToolbar

final class UsageAggregatorTests: XCTestCase {

    private var bundle: Bundle { Bundle(for: type(of: self)) }

    // MARK: - Block boundary

    func test_blockBoundary_splitsAtFiveHourGap() throws {
        let events = try FixtureLoader.events(for: "block-boundary", in: bundle)
        // Sanity: fixture should produce 4 raw events.
        XCTAssertEqual(events.count, 4, "fixture should decode to 4 events")

        let blocks = UsageAggregator.blocks(events: events.sorted { $0.timestamp < $1.timestamp })

        // The fixture has events at 10:00, 11:00, then a >5h gap (>5h to 17:30
        // since gap is 6h30m), then events at 17:30 and 18:00.
        XCTAssertEqual(blocks.count, 2, "expected two blocks separated by a >5h gap")
        XCTAssertEqual(blocks.first?.events.count, 2)
        XCTAssertEqual(blocks.last?.events.count, 2)
    }

    // MARK: - Dedupe contract

    func test_dedupe_acrossFiles() throws {
        // Feed the duplicate-message fixture twice — same file, same ids.
        // The dedupe contract (Set<String> on event.id) should collapse to two
        // unique events regardless of how many times duplicates appear.
        let deduped = try FixtureLoader.dedupedEvents(
            across: ["duplicate-message", "duplicate-message"],
            in: bundle
        )

        XCTAssertEqual(deduped.count, 2, "duplicates should collapse to two unique events")
        let ids = Set(deduped.map(\.id))
        XCTAssertEqual(ids, ["msg-dup:req-dup", "msg-other:req-other"])
    }

    // MARK: - Token math

    func test_totalInputTokens_sumsAllThreeFields() throws {
        let events = try FixtureLoader.events(for: "cache-tokens", in: bundle)
        XCTAssertEqual(events.count, 1)

        let event = try XCTUnwrap(events.first)
        // Fixture has input=1000, cache_create=2000, cache_read=3000, output=500
        XCTAssertEqual(event.inputTokens, 1000)
        XCTAssertEqual(event.cacheCreateTokens, 2000)
        XCTAssertEqual(event.cacheReadTokens, 3000)
        XCTAssertEqual(event.outputTokens, 500)

        // Total input must include all three non-output fields.
        XCTAssertEqual(event.totalInputTokens, 6000,
                       "totalInputTokens must sum input + cache_create + cache_read")
        XCTAssertEqual(event.totalTokens, 6500,
                       "totalTokens must include the output tokens too")
    }

    // MARK: - Empty input

    func test_emptySnapshot_isReturnedFromEmptyEvents() {
        let aggregator = UsageAggregator()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = aggregator.aggregate(events: [], plan: .pro, now: now)

        XCTAssertEqual(snapshot.sessionTokens, 0)
        XCTAssertEqual(snapshot.weeklyTokens, 0)
        XCTAssertEqual(snapshot.opusWeeklyTokens, 0)
        XCTAssertEqual(snapshot.todayCostUSD, 0, accuracy: 0.0001)
        XCTAssertEqual(snapshot.burnRateTokensPerMin, 0, accuracy: 0.0001)
        XCTAssertEqual(snapshot.last7DaysCostUSD.count, 7,
                       "last7DaysCostUSD must always be length 7")
        XCTAssertTrue(snapshot.last7DaysCostUSD.allSatisfy { $0 == 0 },
                      "all seven daily buckets must be zero for empty input")
        XCTAssertNil(snapshot.sessionStart)
        XCTAssertNil(snapshot.sessionResetAt)
    }

    // MARK: - Empty fixture file

    func test_emptyFixture_decodesToNoEvents() throws {
        let events = try FixtureLoader.events(for: "empty", in: bundle)
        XCTAssertEqual(events.count, 0, "empty.jsonl must produce zero events")
    }
}
