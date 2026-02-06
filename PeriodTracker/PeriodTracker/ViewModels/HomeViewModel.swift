import Foundation
import SwiftUI

@Observable
class HomeViewModel {
    var stats: PeriodStats?
    var isLoading = false
    var errorMessage: String?
    var showUnauthorized = false

    var isActive: Bool {
        stats?.currentPeriod != nil
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
            let days = Calendar.current.dateComponents([.day], from: Date(), to: predicted).day ?? 0
            if days > 0 {
                return "Next expected in \(days) day\(days == 1 ? "" : "s")"
            } else if days == 0 {
                return "Expected today"
            } else {
                return "\(-days) day\(-days == 1 ? "" : "s") late"
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
    }

    func togglePeriod() async {
        errorMessage = nil
        do {
            if let current = stats?.currentPeriod {
                _ = try await APIClient.shared.endPeriod(id: current.id, date: Date())
            } else {
                _ = try await APIClient.shared.startPeriod(date: Date())
            }
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
}
