import Foundation
import SwiftUI

@Observable
class LogViewModel {
    var periods: [Period] = []
    var stats: PeriodStats?
    var isLoading = false
    var errorMessage: String?
    var showUnauthorized = false

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let p = APIClient.shared.fetchPeriods()
            async let s = APIClient.shared.fetchStats()
            periods = try await p
            stats = try await s
        } catch let error as APIError {
            if case .unauthorized = error { showUnauthorized = true }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deletePeriod(_ period: Period) async {
        do {
            try await APIClient.shared.deletePeriod(id: period.id)
            await load()
        } catch let error as APIError {
            if case .unauthorized = error { showUnauthorized = true }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updatePeriod(_ period: Period, startDate: Date, endDate: Date?) async {
        do {
            _ = try await APIClient.shared.updatePeriod(id: period.id, startDate: startDate, endDate: endDate)
            await load()
        } catch let error as APIError {
            if case .unauthorized = error { showUnauthorized = true }
            errorMessage = error.errorDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
