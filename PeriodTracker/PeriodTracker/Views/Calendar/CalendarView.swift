import SwiftUI

struct CalendarView: View {
    @State private var vm = CalendarViewModel()
    @Binding var isAuthenticated: Bool

    private let weekdays = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 20) {
                // Month navigation
                HStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) { vm.previousMonth() }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppColor.accent)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text(vm.monthTitle)
                        .font(AppFont.title2)
                        .foregroundStyle(AppColor.textPrimary)

                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) { vm.nextMonth() }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppColor.accent)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal)

                // Weekday headers
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(AppFont.caption)
                            .foregroundStyle(AppColor.textMuted)
                            .frame(height: 30)
                    }
                }
                .padding(.horizontal, 8)

                // Day grid
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(vm.daysInMonth.enumerated()), id: \.offset) { _, date in
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

                if vm.isLoading {
                    ProgressView()
                        .tint(AppColor.accent)
                }

                if let error = vm.errorMessage, !vm.showUnauthorized {
                    Text(error)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.error)
                }

                Spacer()
            }
            .padding(.top, 16)
        }
        .task { await vm.load() }
        .onChange(of: vm.showUnauthorized) { _, val in
            if val { isAuthenticated = false }
        }
    }
}
