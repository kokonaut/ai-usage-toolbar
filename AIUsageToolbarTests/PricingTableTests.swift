import XCTest

@testable import AIUsageToolbar

final class PricingTableTests: XCTestCase {

    /// An unknown opus-named model must hit the opus fallback rates:
    /// input=15, output=75, cache_write=18.75, cache_read=1.5 per Mtok.
    func test_pricingTable_costMatchesExpected() {
        // Pass the test bundle so the loader doesn't accidentally pick up the
        // host app's pricing.json. With no pricing.json in the test bundle,
        // PricingTable falls back to per-family rates, which is what we want
        // to assert against here.
        let pricing = PricingTable(bundle: Bundle(for: type(of: self)))

        let event = UsageEvent(
            id: "msg-opus-test:req-1",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            model: "claude-opus-test",   // unknown name → opus fallback
            cwd: nil,
            gitBranch: nil,
            inputTokens: 1000,
            cacheCreateTokens: 0,
            cacheReadTokens: 0,
            outputTokens: 0
        )

        // 1000 input tokens × $15 / 1M = $0.015
        XCTAssertEqual(pricing.costUSD(for: event), 0.015, accuracy: 0.001)
    }

    /// All four token fields must contribute to cost. This guards the
    /// "input-only" undercount bug.
    func test_pricingTable_allFourFieldsContribute() {
        let pricing = PricingTable(bundle: Bundle(for: type(of: self)))

        let event = UsageEvent(
            id: "msg-mix:req-1",
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            model: "claude-opus-test",
            cwd: nil,
            gitBranch: nil,
            inputTokens: 1_000_000,
            cacheCreateTokens: 1_000_000,
            cacheReadTokens: 1_000_000,
            outputTokens: 1_000_000
        )
        // opus fallback: 15 + 18.75 + 1.5 + 75 = 110.25 USD per 1M-of-each.
        XCTAssertEqual(pricing.costUSD(for: event), 110.25, accuracy: 0.001)
    }
}
