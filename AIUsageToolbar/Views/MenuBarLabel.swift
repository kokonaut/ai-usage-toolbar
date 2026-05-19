import SwiftUI

struct MenuBarLabel: View {
    let snapshot: UsageSnapshot
    let metric: InlineMetric

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge.with.dots.needle.50percent")
            Text(text)
                .monospacedDigit()
        }
        .foregroundStyle(color)
    }

    private var text: String {
        switch metric {
        case .sessionPercent:
            return String(format: "%.0f%%", snapshot.sessionPercent)
        case .timeToReset:
            return timeToResetText
        case .todayCost:
            return String(format: "$%.2f", snapshot.todayCostUSD)
        }
    }

    private var timeToResetText: String {
        guard let resetAt = snapshot.sessionResetAt else { return "—" }
        let interval = resetAt.timeIntervalSince(.now)
        guard interval > 0 else { return "0m" }
        let totalMinutes = Int(interval / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    private var color: Color {
        switch snapshot.sessionPercent {
        case ..<60:  return .primary
        case ..<85:  return .yellow
        case ..<95:  return .orange
        default:     return .red
        }
    }
}
