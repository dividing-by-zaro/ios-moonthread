import Foundation
import SwiftUI

@Observable
class CalendarViewModel {
    var periods: [Period] = []
    var displayedMonth: Date = Date()
    var isLoading = false
    var errorMessage: String?
    var showUnauthorized = false

    private let calendar = Calendar.current

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
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

    func previousMonth() {
        if let date = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = date
        }
    }

    func nextMonth() {
        if let date = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = date
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
