import Foundation
import SwiftUI

@Observable
class CalendarViewModel {
    var periods: [Period] = []
    var stats: PeriodStats?
    var months: [Date] = []
    var isLoading = false
    var errorMessage: String?
    var showUnauthorized = false
    var predictedPeriodDays: Set<Date> = []
    let currentMonthStart: Date

    private let calendar = Calendar.current
    private let batchSize = 12
    private let pastMonths = 24

    init() {
        let now = Date()
        currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        // Past months (oldest first) → current → future months
        for i in -pastMonths...batchSize {
            if let month = calendar.date(byAdding: .month, value: i, to: currentMonthStart) {
                months.append(month)
            }
        }
    }

    func monthTitle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = calendar.component(.month, from: date) == 1 ? "MMMM yyyy" : "MMMM"
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

    func isPredictedDay(_ date: Date) -> Bool {
        let day = calendar.startOfDay(for: date)
        return predictedPeriodDays.contains(day) && !isPeriodDay(date)
    }

    func loadMoreIfNeeded(currentMonth: Date) {
        guard let last = months.last, currentMonth == last else { return }
        for i in 1...batchSize {
            if let month = calendar.date(byAdding: .month, value: i, to: last) {
                months.append(month)
            }
        }
    }

    private func computePredictions() {
        guard let stats else { predictedPeriodDays = []; return }

        let predictedDuration = max(1, stats.predictedPeriodLengthDays ?? 5)
        let predictedCycle = stats.predictedCycleLengthDays
        let today = calendar.startOfDay(for: Date())

        var days = Set<Date>()

        // Predict remaining days of an in-progress period using the shared stats duration.
        if let current = stats.currentPeriod, current.isActive {
            let start = calendar.startOfDay(for: current.startDate)
            let elapsedDays = calendar.dateComponents([.day], from: start, to: today).day ?? 0
            for d in (elapsedDays + 1)..<max(elapsedDays + 1, predictedDuration) {
                if let day = calendar.date(byAdding: .day, value: d, to: start) {
                    days.insert(day)
                }
            }
        }

        if let predictedNextStart = stats.predictedNextStart {
            let firstPredictedStart = calendar.startOfDay(for: predictedNextStart)

            if let predictedCycle {
                for i in 0..<24 {
                    if let start = calendar.date(byAdding: .day, value: predictedCycle * i, to: firstPredictedStart) {
                        for d in 0..<predictedDuration {
                            if let day = calendar.date(byAdding: .day, value: d, to: start) {
                                days.insert(day)
                            }
                        }
                    }
                }
            } else {
                for d in 0..<predictedDuration {
                    if let day = calendar.date(byAdding: .day, value: d, to: firstPredictedStart) {
                        days.insert(day)
                    }
                }
            }
        }
        predictedPeriodDays = days
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let fetchedPeriods = APIClient.shared.fetchPeriods()
            async let fetchedStats = APIClient.shared.fetchStats()
            periods = try await fetchedPeriods
            stats = try await fetchedStats
            computePredictions()
        } catch let error as APIError {
            if case .unauthorized = error { showUnauthorized = true }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
