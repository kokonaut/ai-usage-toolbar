import Foundation
import OSLog

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot = .empty
    @Published var planTier: PlanTier {
        didSet { defaults.set(planTier.rawValue, forKey: Self.planTierKey) }
    }
    @Published var inlineMetric: InlineMetric {
        didSet { defaults.set(inlineMetric.rawValue, forKey: Self.inlineMetricKey) }
    }

    private let log = Logger(subsystem: "dev.kokonaut.AIUsageToolbar", category: "AppState")
    private let aggregator = UsageAggregator()
    private let reader = ClaudeJSONLReader()
    private let fileMonitor = FileMonitor()
    private let defaults: UserDefaults
    private var refreshTask: Task<Void, Never>?
    private var monitorTask: Task<Void, Never>?

    static let planTierKey = "planTier"
    static let inlineMetricKey = "inlineMetric"

    init(defaults: UserDefaults = .standard, autoStart: Bool = true) {
        self.defaults = defaults
        let storedTier = defaults.string(forKey: Self.planTierKey)
        let storedMetric = defaults.string(forKey: Self.inlineMetricKey)
        self.planTier = storedTier.flatMap { PlanTier(rawValue: $0) } ?? .pro
        self.inlineMetric = storedMetric.flatMap { InlineMetric(rawValue: $0) } ?? .sessionPercent
        if autoStart { start() }
    }

    deinit {
        refreshTask?.cancel()
        monitorTask?.cancel()
    }

    private func start() {
        fileMonitor.start(paths: reader.projectsRoots().map(\.path))

        refreshTask = Task { [weak self] in
            await self?.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(60))
                await self?.refresh()
            }
        }

        let events = fileMonitor.events
        monitorTask = Task { [weak self] in
            for await _ in events {
                if Task.isCancelled { break }
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
