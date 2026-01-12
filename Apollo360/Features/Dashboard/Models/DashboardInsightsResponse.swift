import Foundation

struct DashboardInsightsResponse: Decodable {
    let success: Bool
    let data: [DashboardInsightPayload]
}

struct DashboardInsightPayload: Decodable {
    let category: String
    let title: String
    let subtitle: String
    let recommendation: String
    let iconUrl: URL?
}
