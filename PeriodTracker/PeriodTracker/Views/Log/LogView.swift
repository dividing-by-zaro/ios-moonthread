import SwiftUI

struct LogView: View {
    @State private var vm = LogViewModel()
    @State private var editingPeriod: Period?
    @Binding var isAuthenticated: Bool

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            List {
                // Stats cards
                HStack(spacing: 12) {
                    StatsCard(
                        title: "Avg Cycle",
                        value: vm.stats?.averageCycleLength.map { String(format: "%.0f", $0) } ?? "—",
                        unit: "days"
                    )
                    StatsCard(
                        title: "Avg Period",
                        value: vm.stats?.averagePeriodLength.map { String(format: "%.0f", $0) } ?? "—",
                        unit: "days"
                    )
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))

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
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(vm.periods) { period in
                        PeriodRow(period: period)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task { await vm.deletePeriod(period) }
                                } label: {
                                    Image(systemName: "trash")
                                }

                                Button {
                                    editingPeriod = period
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .tint(AppColor.accentDim)
                            }
                    }
                }

                if vm.isLoading {
                    ProgressView()
                        .tint(AppColor.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                if let error = vm.errorMessage, !vm.showUnauthorized {
                    Text(error)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.error)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .sheet(item: $editingPeriod) { period in
            EditPeriodSheet(period: period) { startDate, endDate in
                Task { await vm.updatePeriod(period, startDate: startDate, endDate: endDate) }
            }
            .presentationDetents([.medium])
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
