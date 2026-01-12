import Foundation

/// Response returned by `/dashboard/wellness-overview/:patientId`.
struct WellnessOverviewAPIResponse: Decodable {
    let success: Bool
    let data: WellnessOverviewPayload
}

struct WellnessOverviewPayload: Decodable {
    let mode: String
    let overallScore: Int
    let absolute: WellnessAbsoluteBreakdown
    let relative: WellnessRelativeBreakdown?
}

struct WellnessAbsoluteBreakdown: Decodable {
    let activity: Int
    let sleep: Int
    let heart: Int
    let nutrition: Int
}

struct WellnessRelativeBreakdown: Decodable {
    let activity: Int
    let sleep: Int
    let heart: Int
    let nutrition: Int
}
