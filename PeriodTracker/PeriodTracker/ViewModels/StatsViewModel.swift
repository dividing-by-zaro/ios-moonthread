import Foundation
import SwiftUI

@Observable
class StatsViewModel {
    var periods: [Period] = []
    var isLoading = false
    var errorMessage: String?
    var showUnauthorized = false
    var selectedYear: Int? = nil  // nil = all years

    // MARK: - Derived Data

    var availableYears: [Int] {
        let years = Set(periods.map { Calendar.current.component(.year, from: $0.startDate) })
        return years.sorted(by: >)
    }

    var filteredPeriods: [Period] {
        guard let year = selectedYear else { return periods }
        return periods.filter { Calendar.current.component(.year, from: $0.startDate) == year }
    }

    var completedFiltered: [Period] {
        filteredPeriods.filter { !$0.isActive }
    }

    // MARK: - Cycle Lengths

    struct CycleLengthPoint: Identifiable {
        let id = UUID()
        let date: Date
        let length: Int
    }

    var cycleLengths: [CycleLengthPoint] {
        let sorted = filteredPeriods.sorted { $0.startDate < $1.startDate }
        guard sorted.count >= 2 else { return [] }
        var result: [CycleLengthPoint] = []
        for i in 1..<sorted.count {
            let days = Calendar.current.dateComponents([.day], from: sorted[i-1].startDate, to: sorted[i].startDate).day ?? 0
            if days > 0 {
                result.append(CycleLengthPoint(date: sorted[i].startDate, length: days))
            }
        }
        return result
    }

    var averageCycleLength: Double? {
        let lengths = cycleLengths
        guard !lengths.isEmpty else { return nil }
        return Double(lengths.map(\.length).reduce(0, +)) / Double(lengths.count)
    }

    // MARK: - Monthly Days

    struct MonthlyDays: Identifiable {
        let id = UUID()
        let month: Int
        let monthName: String
        let days: Int
    }

    var monthlyPeriodDays: [MonthlyDays] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        let displayYear = selectedYear ?? cal.component(.year, from: Date())

        var counts = [Int: Int]()
        for m in 1...12 { counts[m] = 0 }

        let allRelevant: [Period]
        if let year = selectedYear {
            allRelevant = periods.filter { period in
                let end = period.endDate ?? Date()
                let startYear = cal.component(.year, from: period.startDate)
                let endYear = cal.component(.year, from: end)
                return startYear == year || endYear == year
            }
        } else {
            allRelevant = periods
        }

        for period in allRelevant {
            let end = period.endDate ?? Date()
            var day = period.startDate
            while day <= end {
                if selectedYear == nil || cal.component(.year, from: day) == selectedYear {
                    let m = cal.component(.month, from: day)
                    counts[m, default: 0] += 1
                }
                day = cal.date(byAdding: .day, value: 1, to: day)!
            }
        }

        // When showing all years, average across the number of years with data
        let yearCount = selectedYear == nil ? max(1, availableYears.count) : 1

        return (1...12).map { m in
            let date = cal.date(from: DateComponents(year: displayYear, month: m, day: 1))!
            let days = yearCount > 1 ? Int((Double(counts[m] ?? 0) / Double(yearCount)).rounded()) : (counts[m] ?? 0)
            return MonthlyDays(month: m, monthName: formatter.string(from: date), days: days)
        }
    }

    var totalPeriodDays: Int {
        monthlyPeriodDays.map(\.days).reduce(0, +)
    }

    // MARK: - Period Duration Variation

    struct DurationPoint: Identifiable {
        let id = UUID()
        let date: Date
        let duration: Int
    }

    var periodDurations: [DurationPoint] {
        completedFiltered
            .sorted { $0.startDate < $1.startDate }
            .compactMap { p in
                guard let d = p.durationDays else { return nil }
                return DurationPoint(date: p.startDate, duration: d)
            }
    }

    var averageDuration: Double? {
        let durations = periodDurations
        guard !durations.isEmpty else { return nil }
        return Double(durations.map(\.duration).reduce(0, +)) / Double(durations.count)
    }

    var durationStdDev: Double? {
        let durations = periodDurations
        guard durations.count >= 2, let avg = averageDuration else { return nil }
        let sumSquares = durations.map { pow(Double($0.duration) - avg, 2) }.reduce(0, +)
        return sqrt(sumSquares / Double(durations.count))
    }

    // MARK: - Regularity Score

    var regularityScore: Double? {
        let lengths = cycleLengths.map { Double($0.length) }
        guard lengths.count >= 2 else { return nil }
        let mean = lengths.reduce(0, +) / Double(lengths.count)
        guard mean > 0 else { return nil }
        let variance = lengths.map { pow($0 - mean, 2) }.reduce(0, +) / Double(lengths.count)
        let cv = sqrt(variance) / mean
        // CV of 0 = perfectly regular (score 100), CV of 0.3+ = very irregular (score 0)
        return max(0, min(100, (1.0 - cv / 0.3) * 100))
    }

    var regularityLabel: String {
        guard let score = regularityScore else { return "Not enough data" }
        switch score {
        case 80...100: return "Very regular"
        case 60..<80: return "Regular"
        case 40..<60: return "Moderate variation"
        case 20..<40: return "Somewhat irregular"
        default: return "Irregular"
        }
    }

    // MARK: - Day of Week

    struct DayOfWeekCount: Identifiable {
        let id = UUID()
        let dayName: String
        let dayIndex: Int
        let count: Int
        let isMax: Bool
    }

    var dayOfWeekCounts: [DayOfWeekCount] {
        let cal = Calendar.current
        var counts = [Int: Int]()
        for d in 1...7 { counts[d] = 0 }

        for period in filteredPeriods {
            let weekday = cal.component(.weekday, from: period.startDate)
            counts[weekday, default: 0] += 1
        }

        let maxCount = counts.values.max() ?? 0
        let formatter = DateFormatter()
        formatter.shortWeekdaySymbols = formatter.shortWeekdaySymbols

        // Reorder to Mon-Sun (weekday 2-7, then 1)
        let order = [2, 3, 4, 5, 6, 7, 1]
        return order.map { day in
            DayOfWeekCount(
                dayName: formatter.shortWeekdaySymbols[day - 1],
                dayIndex: day,
                count: counts[day] ?? 0,
                isMax: counts[day] == maxCount && maxCount > 0
            )
        }
    }

    // MARK: - Load

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
