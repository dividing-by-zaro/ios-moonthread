import Foundation

struct Period: Codable, Identifiable {
    let id: Int
    let startDate: Date
    let endDate: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case startDate = "start_date"
        case endDate = "end_date"
        case createdAt = "created_at"
    }

    var isActive: Bool { endDate == nil }

    var durationDays: Int? {
        guard let end = endDate else { return nil }
        return Calendar.current.dateComponents([.day], from: startDate, to: end).day.map { $0 + 1 }
    }

    var daysSinceStart: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
    }
}

struct PeriodStats: Codable {
    let averageCycleLength: Double?
    let averagePeriodLength: Double?
    let currentPeriod: Period?
    let predictedNextStart: Date?

    enum CodingKeys: String, CodingKey {
        case averageCycleLength = "average_cycle_length"
        case averagePeriodLength = "average_period_length"
        case currentPeriod = "current_period"
        case predictedNextStart = "predicted_next_start"
    }
}
