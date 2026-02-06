import Foundation
import SwiftUI

@Observable
class CalendarViewModel {
    var periods: [Period] = []
    var months: [Date] = []
    var isLoading = false
    var errorMessage: String?
    var showUnauthorized = false

    private let calendar = Calendar.current
    private let batchSize = 12

    init() {
        let now = Date()
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        for i in 0..<batchSize {
            if let month = calendar.date(byAdding: .month, value: -i, to: currentMonthStart) {
                months.append(month)
            }
        }
    }

    func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    func daysInMonth(for monthDate: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: monthDate),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate))
        else { return [] }

        let weekday = calendar.component(.weekday, from: firstDay)
        let leadingBlanks = weekday - calendar.firstWeekday
        let adjustedBlanks = (leadingBlanks + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: adjustedBlanks)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        return days
    }

    func isPeriodDay(_ date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        return periods.contains { period in
            let start = calendar.startOfDay(for: period.startDate)
            let end = period.endDate.map { calendar.startOfDay(for: $0) } ?? calendar.startOfDay(for: Date())
            return day >= start && day <= end
        }
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func loadMoreIfNeeded(currentMonth: Date) {
        guard let last = months.last, currentMonth == last else { return }
        if let oldest = months.last {
            for i in 1...batchSize {
                if let month = calendar.date(byAdding: .month, value: -i, to: oldest) {
                    months.append(month)
                }
            }
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            periods = try await APIClient.shared.fetchPeriods()
        } catch let error as APIError {
            if case .unauthorized = error { showUnauthorized = true }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
