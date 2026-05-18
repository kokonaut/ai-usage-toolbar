import SwiftUI

struct MenuBarLabel: View {
    let snapshot: UsageSnapshot

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge.with.dots.needle.50percent")
            Text(String(format: "%.0f%%", snapshot.sessionPercent))
                .monospacedDigit()
        }
        .foregroundStyle(color)
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
