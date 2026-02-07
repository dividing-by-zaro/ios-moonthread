import SwiftUI

struct ContentView: View {
    @Binding var isAuthenticated: Bool

    var body: some View {
        TabView {
            HomeView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Home", systemImage: "moonphase.waxing.gibbous")
                }

            CalendarView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }

            LogView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Log", systemImage: "list.bullet")
                }

            StatsView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Stats", systemImage: "chart.xyaxis.line")
                }
        }
        .tint(AppColor.accent)
    }
}
