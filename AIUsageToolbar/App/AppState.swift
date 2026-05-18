import Foundation
import Combine
import OSLog

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot = .empty
    @Published var planTier: PlanTier = .pro
    @Published var inlineMetric: InlineMetric = .sessionPercent

    private let log = Logger(subsystem: "dev.kokonaut.AIUsageToolbar", category: "AppState")
    private let aggregator = UsageAggregator()
    private let reader = ClaudeJSONLReader()
    private var refreshTask: Task<Void, Never>?

    init() {
        start()
    }

    deinit {
        refreshTask?.cancel()
    }

    private func start() {
        refreshTask = Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await self?.refresh()
            }
        }
    }

    func refresh() async {
        do {
            let events = try await reader.readAllEvents()
            let snapshot = aggregator.aggregate(events: events, plan: planTier)
            self.snapshot = snapshot
            log.debug("snapshot updated: session=\(snapshot.sessionPercent, format: .fixed(precision: 1))%, today=$\(snapshot.todayCostUSD, format: .fixed(precision: 2))")
        } catch {
            log.error("failed to refresh: \(error.localizedDescription)")
        }
    }
}

enum InlineMetric: String, CaseIterable, Identifiable {
    case sessionPercent
    case timeToReset
    case todayCost

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sessionPercent: "Session %"
        case .timeToReset:    "Time to reset"
        case .todayCost:      "Today's cost"
        }
    }
}
