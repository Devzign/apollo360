//
//  DailyStory.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

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

struct ActivityDay: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let steps: Int
    let isActive: Bool

    static func == (lhs: ActivityDay, rhs: ActivityDay) -> Bool {
        lhs.label == rhs.label &&
        lhs.steps == rhs.steps &&
        lhs.isActive == rhs.isActive
    }
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
