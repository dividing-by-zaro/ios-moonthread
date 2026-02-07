import SwiftUI

struct LogView: View {
    @State private var vm = LogViewModel()
    @Binding var isAuthenticated: Bool

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Stats cards
                    HStack(spacing: 12) {
                        StatsCard(
                            title: "Cycle",
                            value: vm.stats?.averageCycleLength.map { String(format: "%.0f", $0) } ?? "—",
                            unit: "days"
                        )
                        StatsCard(
                            title: "Period",
                            value: vm.stats?.averagePeriodLength.map { String(format: "%.0f", $0) } ?? "—",
                            unit: "days"
                        )
                    }
                    .padding(.horizontal)

                    // Period list
                    if vm.periods.isEmpty && !vm.isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 40, weight: .thin))
                                .foregroundStyle(AppColor.textMuted)
                            Text("No periods logged yet")
                                .font(AppFont.body)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(vm.periods) { period in
                                PeriodRow(period: period)
                            }
                        }
                        .padding(.horizontal)
                    }

                    if vm.isLoading {
                        ProgressView()
                            .tint(AppColor.accent)
                            .padding(.top, 20)
                    }

                    if let error = vm.errorMessage, !vm.showUnauthorized {
                        Text(error)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.error)
                    }
                }
                .padding(.top, 16)
            }
        }
        .task { await vm.load() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await vm.load() }
        }
        .onChange(of: vm.showUnauthorized) { _, val in
            if val { isAuthenticated = false }
        }
    }
}
