import Foundation

/// Response returned by `/dashboard/activities/:patientId`.
struct ActivitiesAPIResponse: Decodable {
    let success: Bool
    let data: ActivitiesPayload
}

struct ActivitiesPayload: Decodable {
    let title: String
    let subtitle: String
    let weeklyChangePercent: Int
    let chart: [ActivityChartEntry]
    let summary: ActivitySummary
    let message: String
}

struct ActivityChartEntry: Decodable {
    let day: String
    let value: Int
    let isActive: Bool
}

struct ActivitySummary: Decodable {
    let avgSteps: Int
    let activeDays: Int
    let calories: Int
}
