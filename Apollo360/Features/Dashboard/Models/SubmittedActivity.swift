import Foundation

struct SubmittedActivity: Identifiable {
    let id = UUID()
    let category: String
    let metricType: String
    let value: Double
    let unit: String
    let note: String
    let date: Date
}
