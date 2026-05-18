import SwiftUI
import Charts

struct TodayCard: View {
    let snapshot: UsageSnapshot

    var body: some View {
        Card(title: "TODAY") {
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "$%.2f", snapshot.todayCostUSD))
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                Spacer()
                Text("\(Int(snapshot.burnRateTokensPerMin)) tok/min")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            sparkline
                .frame(height: 40)
            Text("Last 7 days")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var sparkline: some View {
        Chart(Array(snapshot.last7DaysCostUSD.enumerated()), id: \.offset) { index, value in
            BarMark(
                x: .value("Day", index),
                y: .value("USD", value)
            )
            .foregroundStyle(.tint)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}
