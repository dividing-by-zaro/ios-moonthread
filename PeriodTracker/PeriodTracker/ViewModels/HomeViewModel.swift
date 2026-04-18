import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    var stats: PeriodStats?
    var isLoading = false
    var errorMessage: String?
    var showUnauthorized = false
    var stalePeriod: Period?
    var showStartDatePicker = false
    var showEndDatePicker = false

    var isActive: Bool {
        stats?.currentPeriod != nil
    }

    var isActionButtonBlocked: Bool {
        stalePeriod != nil
    }

    var suggestedEndDate: Date {
        guard let period = stalePeriod else { return Date() }
        let avgDays = stats?.predictedPeriodLengthDays ?? 5
        let suggested = Calendar.current.date(byAdding: .day, value: avgDays - 1, to: period.startDate) ?? Date()
        return min(suggested, Date())
    }

    var stalePeriodDayCount: Int {
        stalePeriod?.daysSinceStart ?? 0
    }

    var statusText: String {
        guard let stats else { return "—" }
        if let current = stats.currentPeriod {
            let day = current.daysSinceStart + 1
            return "Day \(day)"
        }
        return "No active period"
    }

    var subtitleText: String {
        guard let stats else { return "" }
        if stats.currentPeriod != nil {
            return "Period in progress"
        }
        if let predicted = stats.predictedNextStart {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let dateStr = formatter.string(from: predicted)
            let days = Calendar.current.dateComponents([.day], from: Date(), to: predicted).day ?? 0
            if days > 0 {
                return "Next expected \(dateStr) — in \(days) day\(days == 1 ? "" : "s")"
            } else if days == 0 {
                return "Expected today, \(dateStr)"
            } else {
                return "\(-days) day\(-days == 1 ? "" : "s") late — expected \(dateStr)"
            }
        }
        return "Not enough data for prediction"
    }

    var actionButtonTitle: String {
        isActive ? "Period Ended" : "Period Started"
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            stats = try await APIClient.shared.fetchStats()
        } catch let error as APIError {
            if case .unauthorized = error {
                showUnauthorized = true
            }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
        checkForStalePeriod()
    }

    func togglePeriod() {
        if stats?.currentPeriod != nil {
            showEndDatePicker = true
        } else {
            showStartDatePicker = true
        }
    }

    func startPeriod(date: Date) async {
        errorMessage = nil
        do {
            _ = try await APIClient.shared.startPeriod(date: date)
            showStartDatePicker = false
            await load()
        } catch let error as APIError {
            if case .unauthorized = error {
                showUnauthorized = true
            }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func endPeriod(date: Date) async {
        guard let current = stats?.currentPeriod else { return }
        errorMessage = nil
        do {
            _ = try await APIClient.shared.endPeriod(id: current.id, date: date)
            showEndDatePicker = false
            await load()
        } catch let error as APIError {
            if case .unauthorized = error {
                showUnauthorized = true
            }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func endStalePeriod(date: Date) async {
        guard let period = stalePeriod else { return }
        errorMessage = nil
        do {
            _ = try await APIClient.shared.endPeriod(id: period.id, date: date)
            stalePeriod = nil
            await load()
        } catch let error as APIError {
            if case .unauthorized = error {
                showUnauthorized = true
            }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func checkForStalePeriod() {
        if let current = stats?.currentPeriod, current.daysSinceStart >= 20 {
            stalePeriod = current
        } else {
            stalePeriod = nil
        }
    }
}
