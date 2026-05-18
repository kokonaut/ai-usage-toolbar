import SwiftUI

struct WeeklyCard: View {
    let snapshot: UsageSnapshot

    var body: some View {
        Card(title: "WEEKLY") {
            UsageBar(percent: snapshot.weeklyPercent)
            HStack {
                Text("Trailing 7 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", snapshot.weeklyPercent))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if snapshot.opusWeeklyLimit > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Opus")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    UsageBar(percent: snapshot.opusWeeklyPercent, compact: true)
                }
                .padding(.top, 4)
            }
        }
    }
}
