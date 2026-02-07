import Foundation
import SwiftUI

@Observable
class CalendarViewModel {
    var periods: [Period] = []
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
        let sorted = periods.sorted { $0.startDate < $1.startDate }
        guard sorted.count >= 2 else { predictedPeriodDays = []; return }

        var cycleLengths: [Int] = []
        for i in 1..<sorted.count {
            if let days = calendar.dateComponents([.day], from: sorted[i-1].startDate, to: sorted[i].startDate).day,
               days > 0, days < 90 {
                cycleLengths.append(days)
            }
        }
        guard !cycleLengths.isEmpty else { predictedPeriodDays = []; return }
        let avgCycle = Double(cycleLengths.reduce(0, +)) / Double(cycleLengths.count)

        let durations = sorted.compactMap { $0.durationDays }
        let avgDuration = durations.isEmpty ? 5.0 : Double(durations.reduce(0, +)) / Double(durations.count)

        guard let lastStart = sorted.last?.startDate else { predictedPeriodDays = []; return }
        let roundedCycle = Int(round(avgCycle))
        let roundedDuration = Int(round(avgDuration))
        let today = calendar.startOfDay(for: Date())

        var days = Set<Date>()

        // Predict remaining days of an in-progress period
        if let current = sorted.last, current.isActive {
            let start = calendar.startOfDay(for: current.startDate)
            let elapsedDays = calendar.dateComponents([.day], from: start, to: today).day ?? 0
            for d in (elapsedDays + 1)..<roundedDuration {
                if let day = calendar.date(byAdding: .day, value: d, to: start) {
                    days.insert(day)
                }
            }
        }

        for i in 1...24 {
            if let predictedStart = calendar.date(byAdding: .day, value: roundedCycle * i, to: lastStart) {
                let start = calendar.startOfDay(for: predictedStart)
                guard start >= today else { continue }
                for d in 0..<roundedDuration {
                    if let day = calendar.date(byAdding: .day, value: d, to: start) {
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
            periods = try await APIClient.shared.fetchPeriods()
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
