import SwiftUI

struct PopoverRoot: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    SessionCard(snapshot: state.snapshot)
                    WeeklyCard(snapshot: state.snapshot)
                    TodayCard(snapshot: state.snapshot)
                }
                .padding(12)
            }
            Divider()
            footer
        }
        .frame(width: 340, height: 420)
    }

    private var header: some View {
        HStack {
            Text("Claude Usage")
                .font(.headline)
            Spacer()
            Button {
                Task { await state.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            Button {
                // TODO: open settings window
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var footer: some View {
        HStack {
            Text(updatedAtText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Link("Anthropic Console", destination: URL(string: "https://console.anthropic.com/dashboard")!)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var updatedAtText: String {
        guard state.snapshot.updatedAt != .distantPast else { return "Loading…" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated " + formatter.localizedString(for: state.snapshot.updatedAt, relativeTo: .now)
    }
}
