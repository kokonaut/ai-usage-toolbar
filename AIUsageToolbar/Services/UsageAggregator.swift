import Foundation

/// Folds a chronological list of `UsageEvent`s into a single `UsageSnapshot`.
///
/// The block-boundary algorithm follows ccusage: a new 5-hour block starts on the
/// first event whose timestamp exceeds the previous event's timestamp by more
/// than 5 hours, or at the start of input.
struct UsageAggregator: Sendable {
    let pricing: PricingTable

    init(pricing: PricingTable = .shared) {
        self.pricing = pricing
    }

    func aggregate(events: [UsageEvent], plan: PlanTier, now: Date = .now) -> UsageSnapshot {
        let sorted = events.sorted { $0.timestamp < $1.timestamp }

        let blocks = Self.blocks(events: sorted)
        let activeBlock = blocks.last { $0.isActive(at: now) }

        let sessionTokens = activeBlock?.tokens ?? 0
        let sessionStart = activeBlock?.start
        let sessionResetAt = activeBlock?.end

        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let weeklyEvents = sorted.filter { $0.timestamp >= weekStart }
        let weeklyTokens = weeklyEvents.reduce(0) { $0 + $1.totalTokens }
        let opusWeeklyTokens = weeklyEvents
            .filter { $0.model.lowercased().contains("opus") }
            .reduce(0) { $0 + $1.totalTokens }

        let dayStart = Calendar.current.startOfDay(for: now)
        let todayEvents = sorted.filter { $0.timestamp >= dayStart }
        let todayCostUSD = todayEvents.reduce(0.0) { $0 + pricing.costUSD(for: $1) }

        // 7-day cost buckets, oldest -> newest
        var dailyCosts = Array(repeating: 0.0, count: 7)
        for event in sorted where event.timestamp >= Calendar.current.date(byAdding: .day, value: -6, to: dayStart)! {
            let dayDelta = Calendar.current.dateComponents([.day], from: dayStart, to: Calendar.current.startOfDay(for: event.timestamp)).day ?? 0
            let bucket = 6 + dayDelta
            if (0..<7).contains(bucket) {
                dailyCosts[bucket] += pricing.costUSD(for: event)
            }
        }

        // Burn rate: tokens per minute across the active block, or last 10 min if no block.
        let burnRate: Double = {
            if let block = activeBlock, !block.events.isEmpty {
                let elapsedMin = max(1, now.timeIntervalSince(block.start) / 60.0)
                return Double(block.tokens) / elapsedMin
            }
            let cutoff = now.addingTimeInterval(-10 * 60)
            let recent = sorted.filter { $0.timestamp >= cutoff }
            let tokens = recent.reduce(0) { $0 + $1.totalTokens }
            return Double(tokens) / 10.0
        }()

        return UsageSnapshot(
            sessionTokens: sessionTokens,
            sessionLimit: plan.sessionTokenLimit,
            sessionStart: sessionStart,
            sessionResetAt: sessionResetAt,
            weeklyTokens: weeklyTokens,
            weeklyLimit: plan.weeklyTokenLimit,
            weeklyResetAt: nil,
            opusWeeklyTokens: opusWeeklyTokens,
            opusWeeklyLimit: plan.opusWeeklyTokenLimit,
            todayCostUSD: todayCostUSD,
            burnRateTokensPerMin: burnRate,
            last7DaysCostUSD: dailyCosts,
            updatedAt: now
        )
    }

    static func blocks(events: [UsageEvent]) -> [SessionBlock] {
        guard !events.isEmpty else { return [] }
        var result: [SessionBlock] = []
        var currentStart = events[0].timestamp
        var currentEvents: [UsageEvent] = []

        var previous: Date = events[0].timestamp
        for event in events {
            if event.timestamp.timeIntervalSince(previous) > SessionBlock.windowSeconds && !currentEvents.isEmpty {
                result.append(SessionBlock(start: currentStart, events: currentEvents))
                currentStart = event.timestamp
                currentEvents = []
            }
            currentEvents.append(event)
            previous = event.timestamp
        }
        if !currentEvents.isEmpty {
            result.append(SessionBlock(start: currentStart, events: currentEvents))
        }
        return result
    }
}
