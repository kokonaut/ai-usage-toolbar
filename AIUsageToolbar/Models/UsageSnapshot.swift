import Foundation

/// The values the UI reads. Computed by `UsageAggregator` from a list of `UsageEvent`s.
struct UsageSnapshot: Equatable {
    let sessionTokens: Int
    let sessionLimit: Int
    let sessionStart: Date?
    let sessionResetAt: Date?

    let weeklyTokens: Int
    let weeklyLimit: Int
    let weeklyResetAt: Date?

    let opusWeeklyTokens: Int
    let opusWeeklyLimit: Int

    let todayCostUSD: Double
    let burnRateTokensPerMin: Double
    let last7DaysCostUSD: [Double]   // oldest → newest, length 7

    let updatedAt: Date

    var sessionPercent: Double {
        guard sessionLimit > 0 else { return 0 }
        return min(100, 100.0 * Double(sessionTokens) / Double(sessionLimit))
    }

    var weeklyPercent: Double {
        guard weeklyLimit > 0 else { return 0 }
        return min(100, 100.0 * Double(weeklyTokens) / Double(weeklyLimit))
    }

    var opusWeeklyPercent: Double {
        guard opusWeeklyLimit > 0 else { return 0 }
        return min(100, 100.0 * Double(opusWeeklyTokens) / Double(opusWeeklyLimit))
    }

    static let empty = UsageSnapshot(
        sessionTokens: 0,
        sessionLimit: 44_000,
        sessionStart: nil,
        sessionResetAt: nil,
        weeklyTokens: 0,
        weeklyLimit: 880_000,
        weeklyResetAt: nil,
        opusWeeklyTokens: 0,
        opusWeeklyLimit: 220_000,
        todayCostUSD: 0,
        burnRateTokensPerMin: 0,
        last7DaysCostUSD: Array(repeating: 0, count: 7),
        updatedAt: .distantPast
    )
}
