import Foundation

/// Response returned by `/dashboard/apollo-insights/:patientId`.
struct ApolloInsightsAPIResponse: Decodable {
    let success: Bool
    let data: ApolloInsightsPayload
}

struct ApolloInsightsPayload: Decodable {
    let title: String
    let subtitle: String
    let insights: [ApolloInsightPayload]
}

struct ApolloInsightPayload: Decodable {
    let id: String
    let iconUrl: URL?
    let title: String
    let description: String
}
