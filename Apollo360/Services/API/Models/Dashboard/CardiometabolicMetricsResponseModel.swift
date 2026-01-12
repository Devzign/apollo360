import Foundation

struct CardiometabolicMetricsAPIResponse: Decodable {
    let success: Bool
    let data: CardiometabolicMetricsPayload
}

struct CardiometabolicMetricsPayload: Decodable {
    let title: String
    let subtitle: String
    let metrics: CardiometabolicMetricsSection
}

struct CardiometabolicMetricsSection: Decodable {
    let careTeamMetrics: [String: CardiometabolicMetricPayload]
}

struct CardiometabolicMetricPayload: Decodable {
    let title: String
    let value: String
    let unit: String?
    let trend: String?
    let sparkline: [Double]?
    let tint: String?
}
