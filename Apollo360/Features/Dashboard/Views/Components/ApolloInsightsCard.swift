//
//  ApolloInsightsCard.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI
import Combine
import UIKit

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
                                .foregroundColor(AppColor.primary)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apollo Insights")
                            .font(AppFont.display(size: 18, weight: .bold))
                            .foregroundColor(AppColor.black)
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

    var body: some View {
        let color = impactColor(item.impact)

        return HStack(alignment: .top, spacing: 12) {
            
            Circle()
                .fill(color.opacity(0.18))
                .frame(width: 48, height: 48)
                .overlay(
                    InsightIconView(item: item, tint: color)
                        .font(.system(size: 20, weight: .semibold))
                )
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
//                Text(item.title)
//                    .font(AppFont.body(size: 14, weight: .semibold))
//                    .foregroundColor(AppColor.black)

                TypewriterText(
                    text: item.detail,
                    speed: 0.02,
                    font: AppFont.body(size: 12),
                    color: AppColor.grey
                )
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
    private let iconSize: CGFloat = 30

    var body: some View {
        Group {
            if let url = item.iconURL {
                RemoteInsightIcon(url: url) {
                    fallbackIcon
                }
            } else if let systemImage = item.systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(tint)
            } else {
                fallbackIcon
            }
        }
        .frame(width: iconSize * 1.2, height: iconSize * 1.2)
    }

    private var fallbackIcon: some View {
        Image(systemName: "sparkles")
            .font(.system(size: iconSize, weight: .semibold))
            .foregroundColor(tint)
    }
}

private struct RemoteInsightIcon<Placeholder: View>: View {
    @StateObject private var loader: InsightIconLoader
    let placeholder: Placeholder

    init(url: URL, @ViewBuilder placeholder: () -> Placeholder) {
        _loader = StateObject(wrappedValue: InsightIconLoader(url: url))
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholder
            }
        }
        .onAppear {
            loader.load()
        }
    }
}

private final class InsightIconLoader: ObservableObject {
    @Published var image: UIImage?
    private let url: URL
    private var hasLoaded = false

    init(url: URL) {
        self.url = url
    }

    func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.image = image
            }
        }.resume()
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
