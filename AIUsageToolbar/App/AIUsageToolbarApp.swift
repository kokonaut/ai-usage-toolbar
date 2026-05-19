import SwiftUI

@main
struct AIUsageToolbarApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            PopoverRoot()
                .environmentObject(state)
        } label: {
            MenuBarLabel(snapshot: state.snapshot, metric: state.inlineMetric)
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: "settings") {
            SettingsView()
                .environmentObject(state)
        }
        .windowResizability(.contentSize)
    }
}
