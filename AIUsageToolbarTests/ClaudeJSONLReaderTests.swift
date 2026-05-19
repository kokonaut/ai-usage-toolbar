import XCTest

@testable import AIUsageToolbar

final class ClaudeJSONLReaderTests: XCTestCase {

    private var bundle: Bundle { Bundle(for: type(of: self)) }

    /// Sanity: the reader's per-line decode (mirrored in FixtureLoader) must
    /// produce a UsageEvent whose id matches the documented format
    /// "<messageId>:<requestId>".
    func test_eventId_isMessageIdColonRequestId() throws {
        let events = try FixtureLoader.events(for: "cache-tokens", in: bundle)
        let event = try XCTUnwrap(events.first)
        XCTAssertEqual(event.id, "msg-cache:req-cache")
    }

    /// The model field flows through unchanged so downstream filters (e.g.
    /// "model.lowercased().contains("opus")") behave as expected.
    func test_modelField_preserved() throws {
        let events = try FixtureLoader.events(for: "cache-tokens", in: bundle)
        let event = try XCTUnwrap(events.first)
        XCTAssertEqual(event.model, "claude-opus-4")
    }
}
