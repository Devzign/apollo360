import Foundation
import SwiftUI

enum WellnessMode: String, CaseIterable {
    case absolute = "Absolute"
    case relative = "Relative"

    init(apiValue: String) {
        self = WellnessMode(rawValue: apiValue.capitalized) ?? .absolute
    }
}

struct DailyStory: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String?
    let tint: Color
    let hasUpdate: Bool
    let isViewed: Bool
    let imageName: String?
    let iconURL: URL?
    let headline: String?
    let detail: String?
    let recommendation: String?

    init(
        title: String,
        systemImage: String? = nil,
        tint: Color,
        hasUpdate: Bool,
        isViewed: Bool,
        imageName: String? = nil,
        iconURL: URL? = nil,
        headline: String? = nil,
        detail: String? = nil,
        recommendation: String? = nil
    ) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
        self.hasUpdate = hasUpdate
        self.isViewed = isViewed
        self.imageName = imageName
        self.iconURL = iconURL
        self.headline = headline
        self.detail = detail
        self.recommendation = recommendation
    }
}

struct WellnessMetric: Identifiable {
    let id = UUID()
    let title: String
    let current: Int
    let previous: Int
    let tint: Color
}

enum InsightImpact {
    case positive
    case neutral
    case attention
}

struct InsightItem: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String?
    let iconURL: URL?
    let impact: InsightImpact

    init(
        id: String = UUID().uuidString,
        title: String,
        detail: String,
        systemImage: String? = nil,
        iconURL: URL? = nil,
        impact: InsightImpact
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.systemImage = systemImage
        self.iconURL = iconURL
        self.impact = impact
    }
}

struct CardioMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let unit: String
    let trend: String
    let tint: Color
    let sparkline: [Double]
}

struct ActivityDay: Identifiable {
    let id = UUID()
    let label: String
    let steps: Int
    let isActive: Bool
}

struct ActivityStat: Identifiable {
    let id = UUID()
    let value: String
    let title: String
    let systemImage: String
    let tint: Color
}

struct DashboardInsightSnapshot: Identifiable {
    let id: String
    let category: String
    let title: String
    let subtitle: String
    let recommendation: String
    let iconURL: URL?
}

struct WellnessBreakdown {
    let activity: Int
    let sleep: Int
    let heart: Int
    let nutrition: Int
}

struct WellnessRelativeData {
    let lastWeek: Int
    let thisWeek: Int
    let delta: Int
    let breakdown: WellnessBreakdown
}

struct WellnessOverviewResponse {
    let mode: WellnessMode
    let overallScore: Int
    let relative: WellnessRelativeData
}

struct ApolloInsightDetail: Identifiable {
    let id: String
    let iconURL: URL?
    let title: String
    let description: String
}

enum DashboardAPIMock {
    static let insightSnapshots: [DashboardInsightSnapshot] = [
        DashboardInsightSnapshot(
            id: "sleep-quality",
            category: "RPM",
            title: "Your sleep quality improved to 7.5 hours average",
            subtitle: "Your sleep isn’t always fully restful",
            recommendation: "Keep your bedtime routine consistent",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/10303/10303407.png")
        ),
        DashboardInsightSnapshot(
            id: "steady-activity",
            category: "Activity",
            title: "Activity levels are steady at 6,200 daily steps",
            subtitle: "Your body responds well to movement",
            recommendation: "Try adding a 10-minute walk after lunch",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/9289/9289679.png")
        ),
        DashboardInsightSnapshot(
            id: "hr-patterns",
            category: "RPM",
            title: "Heart rate patterns look stable this week",
            subtitle: "Your heart stays steady through daily activity",
            recommendation: "Continue your current wellness routine",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/11410/11410155.png")
        ),
        DashboardInsightSnapshot(
            id: "a1c-stable",
            category: "Labs",
            title: "Your A1C has been stable for the past 3 months",
            subtitle: "Blood sugar levels are well managed",
            recommendation: "Continue your current nutrition plan",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/6401/6401477.png")
        ),
        DashboardInsightSnapshot(
            id: "cholesterol-control",
            category: "Labs",
            title: "Cholesterol levels are within healthy range",
            subtitle: "Cardiovascular risk is controlled",
            recommendation: "Maintain heart-healthy eating habits",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/6401/6401477.png")
        ),
        DashboardInsightSnapshot(
            id: "medication-streak",
            category: "Medications",
            title: "You've maintained a 7-day medication streak",
            subtitle: "Medication adherence is strong",
            recommendation: "Great consistency with your routine",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/809/809957.png")
        ),
        DashboardInsightSnapshot(
            id: "mood-check",
            category: "Mood",
            title: "How are you feeling today?",
            subtitle: "Your mood helps personalize your care",
            recommendation: "Share how you're feeling",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/1791/1791293.png")
        ),
        DashboardInsightSnapshot(
            id: "active-days",
            category: "Activity",
            title: "You've been active 5 out of 7 days this week",
            subtitle: "Weekly activity summary",
            recommendation: "Add gentle stretching on rest days",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/9289/9289679.png")
        )
    ]

    static let wellnessOverview = WellnessOverviewResponse(
        mode: .relative,
        overallScore: 84,
        relative: WellnessRelativeData(
            lastWeek: 72,
            thisWeek: 84,
            delta: 12,
            breakdown: WellnessBreakdown(activity: -1, sleep: 0, heart: 1, nutrition: -2)
        )
    )

    static let apolloInsights: [ApolloInsightDetail] = [
        ApolloInsightDetail(
            id: "sleep-recovery",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/12148/12148922.png"),
            title: "Sleep & Recovery Connection",
            description: "On nights with 7+ hours of sleep, your resting heart rate is 8 bpm lower the next morning."
        ),
        ApolloInsightDetail(
            id: "activity-pattern",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/12073/12073386.png"),
            title: "Activity Pattern",
            description: "Your most consistent activity days are Tuesday and Thursday. Building on this routine could help."
        ),
        ApolloInsightDetail(
            id: "hrv",
            iconURL: URL(string: "https://cdn-icons-png.flaticon.com/128/865/865969.png"),
            title: "Heart Rate Variability",
            description: "Your HRV improves on days following evening walks. Consider adding more gentle movement."
        )
    ]
}
