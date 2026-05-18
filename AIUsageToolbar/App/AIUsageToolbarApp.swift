import SwiftUI

// MenuBarExtraAccess will be wired back in when we need NSStatusItem escape
// hatches (settings window, popover sizing). For v0 the vanilla MenuBarExtra
// API is sufficient.

@main
struct AIUsageToolbarApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        MenuBarExtra {
            PopoverRoot()
                .environmentObject(state)
        } label: {
            MenuBarLabel(snapshot: state.snapshot)
        }
        .menuBarExtraStyle(.window)
    }
}
