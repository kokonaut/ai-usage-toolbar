import SwiftUI

struct SessionCard: View {
    let snapshot: UsageSnapshot

    var body: some View {
        Card(title: "5-HOUR SESSION") {
            UsageBar(percent: snapshot.sessionPercent)
            HStack {
                Text(resetText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.0f%%", snapshot.sessionPercent))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var resetText: String {
        guard let reset = snapshot.sessionResetAt else { return "No active session" }
        let interval = max(0, reset.timeIntervalSinceNow)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "Resets in \(hours)h \(minutes)m"
    }
}
