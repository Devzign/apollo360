//
//  HomeSections.swift
//  Apollo360
//
//  Created by Codex on 28/01/26.
//

import SwiftUI

struct StoriesSectionView: View {
    let title: String
    let subtitle: String
    let stories: [DailyStory]

    var body: some View {
        DailyStoriesView(
            title: title,
            subtitle: subtitle,
            stories: stories
        )
        .scrollFadeScale()
    }
}

struct WellnessSectionView: View {
    let title: String
    let description: String
    let currentScore: Int
    let previousScore: Int
    let progress: Double
    let metrics: [WellnessMetric]
    let isImproving: Bool
    let changeValue: Int
    @Binding var mode: WellnessMode

    var body: some View {
        WellnessScoreCard(
            title: title,
            description: description,
            currentScore: currentScore,
            previousScore: previousScore,
            progress: progress,
            metrics: metrics,
            isImproving: isImproving,
            changeValue: changeValue,
            mode: $mode
        )
        .scrollFadeScale()
    }
}

struct InsightsSectionView: View {
    let insights: [InsightItem]

    var body: some View {
        ApolloInsightsCard(insights: insights)
            .scrollFadeScale()
    }
}

struct CardioSectionView: View {
    let metrics: [CardioMetric]

    var body: some View {
        CardiometabolicMetricsCard(metrics: metrics)
            .scrollFadeScale()
    }
}

struct ActivitiesSectionView: View {
    let days: [ActivityDay]
    let stats: [ActivityStat]
    let summaryNote: String
    let weeklyChangePercent: Int

    var body: some View {
        ActivitiesSummaryCard(
            days: days,
            stats: stats,
            summaryNote: summaryNote,
            weeklyChangePercent: weeklyChangePercent
        )
        .scrollFadeScale()
    }
}
