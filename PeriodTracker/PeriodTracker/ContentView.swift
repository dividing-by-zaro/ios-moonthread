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

            LogView(isAuthenticated: $isAuthenticated)
                .tabItem {
                    Label("Log", systemImage: "list.bullet")
                }
        }
        .tint(AppColor.accent)
    }
}
