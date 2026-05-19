import XCTest

@testable import AIUsageToolbar

final class PlanLimitsTests: XCTestCase {

    /// Regression guard against accidental edits to the hardcoded plan caps.
    /// These literals MUST match `PlanLimits.swift`. If a tier's numbers are
    /// updated upstream, update this test deliberately.
    func test_planTier_limits() {
        // Pro
        XCTAssertEqual(PlanTier.pro.sessionTokenLimit, 44_000)
        XCTAssertEqual(PlanTier.pro.weeklyTokenLimit, 880_000)
        XCTAssertEqual(PlanTier.pro.opusWeeklyTokenLimit, 0)

        // Max 5×
        XCTAssertEqual(PlanTier.max5.sessionTokenLimit, 88_000)
        XCTAssertEqual(PlanTier.max5.weeklyTokenLimit, 4_400_000)
        XCTAssertEqual(PlanTier.max5.opusWeeklyTokenLimit, 440_000)

        // Max 20×
        XCTAssertEqual(PlanTier.max20.sessionTokenLimit, 220_000)
        XCTAssertEqual(PlanTier.max20.weeklyTokenLimit, 22_000_000)
        XCTAssertEqual(PlanTier.max20.opusWeeklyTokenLimit, 2_200_000)
    }
}
