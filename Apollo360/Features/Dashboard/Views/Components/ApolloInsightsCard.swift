//
//  ApolloInsightsCard.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI

struct ApolloInsightsCard: View {
    let insights: [InsightItem]

    var body: some View {
        DashboardCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(AppColor.primary.opacity(0.12))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppColor.primary)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apollo Insights")
                            .font(AppFont.display(size: 18, weight: .bold))
                            .foregroundStyle(AppColor.black)
                    }
                    Spacer()
                }

                VStack(spacing: 12) {
                    ForEach(insights) { insight in
                        InsightRowView(item: insight)
                    }
                }
            }
        }
    }
}

private struct InsightRowView: View {
    let item: InsightItem
    @State private var revealProgress: CGFloat = 0

    var body: some View {
        let color = impactColor(item.impact)

        return HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 36, height: 36)
                .overlay(
                    InsightIconView(item: item, tint: color)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(AppFont.body(size: 14, weight: .semibold))
                    .foregroundStyle(AppColor.black)

                Text(item.detail)
                    .font(AppFont.body(size: 12))
                    .foregroundStyle(AppColor.grey)
            }

            Spacer()
        }
        .padding(12)
        .background(color.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 4)
                .padding(.horizontal, 8)
                .scaleEffect(x: revealProgress, y: 1, anchor: .leading)
        }
        .onAppear {
            revealProgress = 0
            withAnimation(.easeOut(duration: 1.0)) {
                revealProgress = 1
            }
        }
    }

    private func impactColor(_ impact: InsightImpact) -> Color {
        switch impact {
        case .positive:
            return AppColor.green
        case .neutral:
            return AppColor.primary
        case .attention:
            return AppColor.yellow
        }
    }
}

private struct InsightIconView: View {
    let item: InsightItem
    let tint: Color
    private let iconSize: CGFloat = 16

    var body: some View {
        Group {
            if let url = item.iconURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if phase.error != nil {
                        fallbackIcon
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            } else if let systemImage = item.systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundStyle(tint)
            } else {
                fallbackIcon
            }
        }
        .frame(width: iconSize * 1.2, height: iconSize * 1.2)
    }

    private var fallbackIcon: some View {
        Image(systemName: "sparkles")
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundStyle(tint)
    }
}

#Preview {
    ApolloInsightsCard(
        insights: [
            InsightItem(
                id: "00000000-0000-0000-0000-000000000001",
                title: "Sleep & Recovery Connection",
                detail: "On nights with 7+ hours of sleep, your resting heart rate is 8 bpm lower the next morning.",
                systemImage: "moon.stars.fill", iconURL: nil,
                impact: .positive
            ),
            InsightItem(
                id: "00000000-0000-0000-0000-000000000002",
                title: "Activity Pattern",
                detail: "Your most consistent activity days are Tuesday and Thursday. Building on this routine could help.",
                systemImage: "figure.walk.circle.fill", iconURL: nil,
                impact: .neutral
            ),
            InsightItem(
                id: "00000000-0000-0000-0000-000000000003",
                title: "Heart Rate Variability",
                detail: "Your HRV improves on days following evening walks. Consider adding more gentle movement.",
                systemImage: "heart.circle.fill", iconURL: nil,
                impact: .attention
            )
        ]
    )
    .padding()
}
