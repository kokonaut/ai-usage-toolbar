import XCTest
@testable import AIUsageToolbar

@MainActor
final class AppStateTests: XCTestCase {

    private func freshDefaults() -> UserDefaults {
        let suite = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func test_persistence_roundTrips_planTier() {
        let defaults = freshDefaults()

        let first = AppState(defaults: defaults, autoStart: false)
        XCTAssertEqual(first.planTier, .pro)
        first.planTier = .max20

        let second = AppState(defaults: defaults, autoStart: false)
        XCTAssertEqual(second.planTier, .max20)
    }

    func test_persistence_roundTrips_inlineMetric() {
        let defaults = freshDefaults()

        let first = AppState(defaults: defaults, autoStart: false)
        XCTAssertEqual(first.inlineMetric, .sessionPercent)
        first.inlineMetric = .todayCost

        let second = AppState(defaults: defaults, autoStart: false)
        XCTAssertEqual(second.inlineMetric, .todayCost)
    }

    func test_init_fallsBackToDefaultsWhenStoredValueUnparseable() {
        let defaults = freshDefaults()
        defaults.set("not-a-real-tier", forKey: AppState.planTierKey)
        defaults.set("not-a-real-metric", forKey: AppState.inlineMetricKey)

        let state = AppState(defaults: defaults, autoStart: false)
        XCTAssertEqual(state.planTier, .pro)
        XCTAssertEqual(state.inlineMetric, .sessionPercent)
    }
}
