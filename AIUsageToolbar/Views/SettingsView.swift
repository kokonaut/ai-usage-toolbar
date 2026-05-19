import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        Form {
            Section("Plan") {
                Picker("Plan tier", selection: $state.planTier) {
                    ForEach(PlanTier.allCases) { tier in
                        Text(tier.displayName).tag(tier)
                    }
                }
                .pickerStyle(.menu)
                Text("Token thresholds for the 5-hour window and 7-day cap are heuristics — community-sourced and prone to drift.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Menu Bar") {
                Picker("Inline metric", selection: $state.inlineMetric) {
                    ForEach(InlineMetric.allCases) { metric in
                        Text(metric.label).tag(metric)
                    }
                }
                .pickerStyle(.menu)
                Text("What the menu bar shows next to the gauge: percent used, time until reset, or today's spend.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 360)
    }
}
