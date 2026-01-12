import Combine
import Foundation
import SwiftUI

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var stories: [DailyStory]
    @Published var isLoadingInsights: Bool = false
    @Published var insightError: String?
    @Published var wellnessMode: WellnessMode
    @Published var currentScore: Int
    @Published var previousScore: Int
    @Published var progress: Double
    @Published var wellnessMetrics: [WellnessMetric]
    @Published var changeValue: Int
    @Published var insights: [InsightItem]
    @Published var cardioMetrics: [CardioMetric]
    @Published var activityDays: [ActivityDay]
    @Published var activityStats: [ActivityStat]
    @Published var activitySummaryNote: String
    @Published var weeklyChangePercent: Int

    let session: SessionManager
    private var relativeBreakdown: WellnessBreakdown
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    let greeting = "Good morning,"
    let userName = "Amit Sinha"

    let snapshotTitle = "Your Daily Snapshot"
    let snapshotSubtitle = "Personalized stories generated from your data to help you understand trends and take simple, supportive actions."

    let wellnessTitle = "Wellness Overview"
    let wellnessDescription = "Your current wellness level based on activity, sleep, heart health, and nutrition patterns."

    var wellnessChange: Int {
        changeValue
    }

    var isWellnessImproving: Bool {
        changeValue >= 0
    }

    init(session: SessionManager) {
        self.session = session
        let overview = DashboardAPIMock.wellnessOverview
        self.relativeBreakdown = overview.relative.breakdown
        self.wellnessMode = overview.mode
        self.currentScore = overview.overallScore
        self.previousScore = overview.relative.lastWeek
        self.changeValue = overview.relative.delta
        self.progress = Double(overview.overallScore) / 100.0
        self.wellnessMetrics = Self.metrics(current: overview.relative.breakdown,
                                            previous: overview.relative.breakdown)
        self.stories = Self.defaultStories()
        self.insights = DashboardAPIMock.apolloInsights.enumerated().map { index, detail in
            InsightItem(
                id: detail.id,
                title: detail.title,
                detail: detail.description,
                iconURL: detail.iconURL,
                impact: Self.impact(for: index)
            )
        }
        self.cardioMetrics = [
            CardioMetric(
                title: "Blood Pressure",
                value: "121/77",
                unit: "mmHg",
                trend: "+1% from last week",
                tint: AppColor.red,
                sparkline: [0.62, 0.64, 0.61, 0.66, 0.63, 0.65, 0.64]
            ),
            CardioMetric(
                title: "Resting Heart Rate",
                value: "65",
                unit: "bpm",
                trend: "-3 bpm from last week",
                tint: AppColor.green,
                sparkline: [0.56, 0.52, 0.54, 0.51, 0.49, 0.5, 0.48]
            ),
            CardioMetric(
                title: "Glucose",
                value: "96",
                unit: "mg/dL",
                trend: "Stable this week",
                tint: AppColor.yellow,
                sparkline: [0.48, 0.52, 0.5, 0.47, 0.49, 0.48, 0.46]
            )
        ]
        self.activityDays = [
            ActivityDay(label: "M", steps: 8234, isActive: true),
            ActivityDay(label: "T", steps: 6521, isActive: true),
            ActivityDay(label: "W", steps: 4102, isActive: false),
            ActivityDay(label: "T", steps: 7845, isActive: true),
            ActivityDay(label: "F", steps: 9012, isActive: true),
            ActivityDay(label: "S", steps: 5234, isActive: true),
            ActivityDay(label: "S", steps: 3421, isActive: false)
        ]
        self.activityStats = [
            ActivityStat(value: Self.formatNumber(6338), title: "Avg Steps", systemImage: "figure.walk", tint: AppColor.primary),
            ActivityStat(value: "5/7", title: "Active Days", systemImage: "checkmark.circle", tint: AppColor.green),
            ActivityStat(value: Self.formatNumber(1775), title: "Calories", systemImage: "flame", tint: AppColor.yellow)
        ]
        self.activitySummaryNote = "Great consistency! You have been active 5 out of 7 days."
        self.weeklyChangePercent = 12

        fetchWellnessOverview()
        fetchApolloInsights()
        fetchCardiometabolicMetrics()
        fetchActivities()
    }

    private func fetchWellnessOverview() {
        guard let patientId = session.patientId else {
            return
        }
        APIClient.shared.fetchWellnessOverview(patientId: patientId, mode: .absolute) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let payload):
                self.wellnessMode = WellnessMode(apiValue: payload.mode)
                self.currentScore = payload.overallScore
                self.progress = min(Double(payload.overallScore) / 100.0, 1.0)
                let currentBreakdown = Self.breakdown(from: payload.absolute)
                if let relative = payload.relative {
                    let mapped = WellnessBreakdown(activity: relative.activity, sleep: relative.sleep, heart: relative.heart, nutrition: relative.nutrition)
                    self.relativeBreakdown = mapped
                }
                self.updateMetrics(using: currentBreakdown)
                self.changeValue = self.currentScore - self.previousScore
            case .failure:
                break
            }
        }
    }

    private func fetchApolloInsights() {
        guard let patientId = session.patientId else { return }
        isLoadingInsights = true
        APIClient.shared.fetchApolloInsights(patientId: patientId) { [weak self] result in
            guard let self else { return }
            self.isLoadingInsights = false
            switch result {
            case .success(let payload):
                self.insights = payload.insights.enumerated().map { index, insight in
                    InsightItem(
                        id: insight.id,
                        title: insight.title,
                        detail: insight.description,
                        iconURL: insight.iconUrl,
                        impact: Self.impact(for: index)
                    )
                }
                self.insightError = nil
            case .failure(let error):
                self.insightError = error.localizedDescription
            }
        }
    }

    private func fetchCardiometabolicMetrics() {
        guard let patientId = session.patientId else { return }
        APIClient.shared.fetchCardiometabolicMetrics(patientId: patientId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let payload):
                let mapped = payload.metrics.careTeamMetrics.values.sorted { $0.title < $1.title }.map { metric in
                    CardioMetric(
                        title: metric.title,
                        value: metric.value,
                        unit: metric.unit ?? "",
                        trend: metric.trend ?? "",
                        tint: self.tintColor(for: metric.tint),
                        sparkline: self.normalizedSparkline(metric.sparkline)
                    )
                }
                if !mapped.isEmpty {
                    self.cardioMetrics = mapped
                }
            case .failure:
                break
            }
        }
    }

    private func fetchActivities() {
        guard let patientId = session.patientId else { return }
        APIClient.shared.fetchActivities(patientId: patientId) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let payload):
                self.activityDays = payload.chart.map { entry in
                    ActivityDay(label: entry.day, steps: entry.value, isActive: entry.isActive)
                }
                self.activityStats = [
                    ActivityStat(value: Self.formatNumber(payload.summary.avgSteps), title: "Avg Steps", systemImage: "figure.walk", tint: AppColor.primary),
                    ActivityStat(value: "\(payload.summary.activeDays)/7", title: "Active Days", systemImage: "checkmark.circle", tint: AppColor.green),
                    ActivityStat(value: Self.formatNumber(payload.summary.calories), title: "Calories", systemImage: "flame", tint: AppColor.yellow)
                ]
                self.activitySummaryNote = payload.message
                self.weeklyChangePercent = payload.weeklyChangePercent
            case .failure:
                break
            }
        }
    }

    private func updateMetrics(using current: WellnessBreakdown) {
        wellnessMetrics = Self.metrics(current: current, previous: relativeBreakdown)
    }

    private static func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(value: value)
        return formatter.string(from: number) ?? "\(value)"
    }

    private func tintColor(for value: String?) -> Color {
        guard let value = value?.lowercased() else { return AppColor.primary }
        switch value {
        case "green": return AppColor.green
        case "red": return AppColor.red
        case "yellow": return AppColor.yellow
        case "blue": return AppColor.blue
        case "primary": return AppColor.primary
        default: return AppColor.primary
        }
    }

    private func normalizedSparkline(_ values: [Double]?) -> [Double] {
        if let existing = values, !existing.isEmpty {
            return existing
        }
        return [0.5, 0.5, 0.5]
    }

    private static func metrics(current: WellnessBreakdown, previous: WellnessBreakdown) -> [WellnessMetric] {
        [
            WellnessMetric(title: "Activity", current: current.activity, previous: previous.activity, tint: AppColor.green),
            WellnessMetric(title: "Sleep", current: current.sleep, previous: previous.sleep, tint: AppColor.blue),
            WellnessMetric(title: "Heart", current: current.heart, previous: previous.heart, tint: AppColor.red),
            WellnessMetric(title: "Nutrition", current: current.nutrition, previous: previous.nutrition, tint: AppColor.yellow)
        ]
    }

    private static func breakdown(from absolute: WellnessAbsoluteBreakdown) -> WellnessBreakdown {
        WellnessBreakdown(
            activity: absolute.activity,
            sleep: absolute.sleep,
            heart: absolute.heart,
            nutrition: absolute.nutrition
        )
    }

    private static func impact(for index: Int) -> InsightImpact {
        switch index {
        case 0: return .positive
        case 1: return .neutral
        default: return .attention
        }
    }

    private static func story(from payload: DashboardInsightPayload) -> DailyStory {
        DailyStory(
            title: payload.category,
            tint: color(for: payload.category),
            hasUpdate: true,
            isViewed: false,
            iconURL: payload.iconUrl,
            headline: payload.title,
            detail: payload.subtitle,
            recommendation: payload.recommendation
        )
    }

    private static func defaultStories() -> [DailyStory] {
        DashboardAPIMock.insightSnapshots.map { snapshot in
            DailyStory(
                title: snapshot.category,
                tint: color(for: snapshot.category),
                hasUpdate: true,
                isViewed: false,
                iconURL: snapshot.iconURL,
                headline: snapshot.title,
                detail: snapshot.subtitle,
                recommendation: snapshot.recommendation
            )
        }
    }

    private static func color(for category: String) -> Color {
        switch category.lowercased() {
        case "rpm":
            return AppColor.green
        case "activity":
            return AppColor.blue
        case "labs":
            return AppColor.primary
        case "medications":
            return AppColor.yellow
        default:
            return AppColor.secondary
        }
    }
}
