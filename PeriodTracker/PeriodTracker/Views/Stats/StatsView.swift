import SwiftUI

struct StatsView: View {
    @State private var vm = StatsViewModel()
    @Binding var isAuthenticated: Bool

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Year picker
                    if !vm.availableYears.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        vm.selectedYear = nil
                                    }
                                } label: {
                                    Text("All")
                                        .font(AppFont.headline)
                                        .foregroundStyle(
                                            vm.selectedYear == nil
                                                ? AppColor.background
                                                : AppColor.textSecondary
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            vm.selectedYear == nil
                                                ? AppColor.accent
                                                : AppColor.surface
                                        )
                                        .clipShape(Capsule())
                                }

                                ForEach(vm.availableYears, id: \.self) { year in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            vm.selectedYear = year
                                        }
                                    } label: {
                                        Text(String(year))
                                            .font(AppFont.headline)
                                            .foregroundStyle(
                                                vm.selectedYear == year
                                                    ? AppColor.background
                                                    : AppColor.textSecondary
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                vm.selectedYear == year
                                                    ? AppColor.accent
                                                    : AppColor.surface
                                            )
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Summary cards
                    HStack(spacing: 12) {
                        StatsCard(
                            title: "Periods",
                            value: "\(vm.filteredPeriods.count)",
                            unit: "total"
                        )
                        StatsCard(
                            title: "Period Days",
                            value: "\(vm.totalPeriodDays)",
                            unit: "days"
                        )
                    }
                    .padding(.horizontal)

                    // Charts
                    ChartCard(title: "Cycle Length Trend") {
                        CycleLengthChart(vm: vm)
                    }

                    ChartCard(title: vm.selectedYear == nil ? "Average Days per Month" : "Days per Month") {
                        MonthlyDaysChart(vm: vm)
                    }

                    ChartCard(title: "Period Duration") {
                        PeriodVariationChart(vm: vm)
                    }

                    if vm.selectedYear != nil {
                        ChartCard(title: "Cycle Regularity") {
                            RegularityGauge(vm: vm)
                        }
                    }

                    if vm.selectedYear == nil {
                        ChartCard(title: "Start Day Patterns") {
                            DayOfWeekChart(vm: vm)
                        }
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
            }

            if vm.isLoading {
                ProgressView()
                    .tint(AppColor.accent)
            }

            if let error = vm.errorMessage, !vm.showUnauthorized {
                Text(error)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
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

// MARK: - ChartCard

struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFont.headline)
                .foregroundStyle(AppColor.textSecondary)

            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}
