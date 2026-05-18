import Foundation

/// A 5-hour rolling window of activity. A new block starts when the gap between
/// successive events exceeds 5 hours, following ccusage's convention.
struct SessionBlock: Equatable {
    static let windowSeconds: TimeInterval = 5 * 60 * 60

    let start: Date
    let events: [UsageEvent]

    var end: Date { start.addingTimeInterval(Self.windowSeconds) }

    var tokens: Int { events.reduce(0) { $0 + $1.totalTokens } }

    func isActive(at now: Date = .now) -> Bool {
        now >= start && now < end
    }

    func remaining(at now: Date = .now) -> TimeInterval {
        max(0, end.timeIntervalSince(now))
    }
}
