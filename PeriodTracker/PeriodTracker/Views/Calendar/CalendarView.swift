import SwiftUI

struct CalendarView: View {
    @State private var vm = CalendarViewModel()
    @Binding var isAuthenticated: Bool

    private let weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky weekday headers
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textMuted)
                            .frame(height: 30)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 16)
                .background(AppColor.background)

                if vm.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppColor.accent)
                    Spacer()
                } else if let error = vm.errorMessage, !vm.showUnauthorized {
                    Spacer()
                    Text(error)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.error)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(vm.months, id: \.self) { month in
                                MonthSection(
                                    month: month,
                                    vm: vm,
                                    columns: columns
                                )
                                .onAppear {
                                    vm.loadMoreIfNeeded(currentMonth: month)
                                }
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
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

private struct MonthSection: View {
    let month: Date
    let vm: CalendarViewModel
    let columns: [GridItem]

    var body: some View {
        VStack(spacing: 12) {
            Text(vm.monthTitle(for: month))
                .font(AppFont.title2)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(vm.daysInMonth(for: month).enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(
                            date: date,
                            isPeriodDay: vm.isPeriodDay(date),
                            isToday: vm.isToday(date)
                        )
                    } else {
                        Color.clear.frame(width: 36, height: 36)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
