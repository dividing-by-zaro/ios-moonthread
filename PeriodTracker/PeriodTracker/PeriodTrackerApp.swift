import SwiftUI

@main
struct PeriodTrackerApp: App {
    @State private var isAuthenticated = KeychainHelper.load() != nil

    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    ContentView(isAuthenticated: $isAuthenticated)
                } else {
                    PasswordEntryView(isAuthenticated: $isAuthenticated)
                }
            }
            .preferredColorScheme(.dark)
            .animation(.easeInOut(duration: 0.3), value: isAuthenticated)
        }
    }
}
