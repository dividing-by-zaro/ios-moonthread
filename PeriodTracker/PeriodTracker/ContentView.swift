import SwiftUI

struct ContentView: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
        TabView {
            HomeView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Home", systemImage: "heart")
                }

            CalendarView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            StatsView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Stats", systemImage: "chart.xyaxis.line")
                }

            LogView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Log", systemImage: "list.bullet")
                }
        }
        .tint(AppColor.accent)
    }
}
