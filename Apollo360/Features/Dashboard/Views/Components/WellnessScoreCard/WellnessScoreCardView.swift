//
//  WellnessScoreCard.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI

struct WellnessScoreCard: View {
    let title: String
    let description: String
    let currentScore: Int
    let previousScore: Int
    let progress: Double
    let metrics: [WellnessMetric]
    let isImproving: Bool
    let changeValue: Int
    @Binding var mode: WellnessMode
    @State private var isShowingBreakdown = false

    var body: some View {
        DashboardCard {
            VStack(alignment: .center, spacing: 6) {
                HStack(alignment: .center) {
                    Text(title)
                        .font(AppFont.display(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.black)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    WellnessModeToggle(selected: $mode)
                }
                .padding(.bottom, 10)

                if mode == .absolute {
                    absoluteView
                } else {
                    relativeView
                }
            }
        }
        .sheet(isPresented: $isShowingBreakdown) {
            ScoreBreakdownView(
                score: currentScore,
                mode: mode,
                metrics: metrics
            )
        }
    }

    private var absoluteView: some View {
        VStack(spacing: 16) {
            WellnessProgressRing(score: currentScore, progress: progress, onTap: {
                isShowingBreakdown = true
            })
            .frame(maxWidth: .infinity)

            Text(description)
                .font(AppFont.body(size: 13))
                .foregroundStyle(AppColor.grey)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: .infinity)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(metrics) { metric in
                    WellnessMetricRow(metric: metric)
                }
            }
        }
    }

    private var relativeView: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("Last Week")
                        .font(AppFont.body(size: 12))
                        .foregroundStyle(AppColor.grey)
                    Text("\(previousScore)")
                        .font(AppFont.display(size: 28, weight: .bold))
                        .foregroundStyle(AppColor.grey)
                }

                TrendIndicatorView(isImproving: isImproving)

                VStack(spacing: 6) {
                    Text("This Week")
                        .font(AppFont.body(size: 12, weight: .medium))
                        .foregroundStyle(AppColor.black)
                    Text("\(currentScore)")
                        .font(AppFont.display(size: 32, weight: .bold))
                        .foregroundStyle(isImproving ? AppColor.green : AppColor.red)
                }
            }

            WellnessChangeBadge(isImproving: isImproving, changeValue: changeValue)

            Text(isImproving
                 ? "Great progress! Your wellness has improved compared to your recent baseline."
                 : "Small changes add up. Focus on one area to improve this week.")
                .font(AppFont.body(size: 13))
                .foregroundStyle(AppColor.grey)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(metrics) { metric in
                    WellnessDeltaRow(metric: metric)
                }
            }
        }
    }
}

private struct WellnessModeToggle: View {
    @Binding var selected: WellnessMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(WellnessMode.allCases, id: \.self) { mode in
                Text(mode.rawValue)
                    .font(AppFont.body(size: 12, weight: .semibold))
                    .foregroundStyle(mode == selected ? AppColor.secondary : AppColor.grey)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                    .background(mode == selected ? AppColor.primary : Color.clear)
                    .clipShape(Capsule())
                    .onTapGesture {
                        selected = mode
                    }
            }
        }
        .padding(3)
        .background(Color.black.opacity(0.05))
        .clipShape(Capsule())
    }
}

private struct WellnessProgressRing: View {
    let score: Int
    let progress: Double
    var onTap: (() -> Void)? = nil
    @State private var animatedProgress: Double = 0
    @State private var pulse: Bool = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.05), lineWidth: 14)

            Circle()
                .stroke(AppColor.blue.opacity(0.12), lineWidth: 32)
                .scaleEffect(pulse ? 1.08 : 0.92)
                .blur(radius: 1)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AppColor.blue,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: AppColor.blue.opacity(0.3),
                    radius: 8
                )

            VStack(spacing: 6) {
                Text("\(score)")
                    .font(AppFont.display(size: 46, weight: .bold))
                    .foregroundStyle(AppColor.black)

                Text("Overall Score")
                    .font(AppFont.body(size: 12))
                    .foregroundStyle(AppColor.grey)
            }
        }
        .frame(width: 220, height: 220)
        .padding(.vertical, 16)
        .contentShape(Circle())
        .onTapGesture {
            onTap?()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = progress
            }
            withAnimation(
                .easeInOut(duration: 1.6).repeatForever(autoreverses: true)
            ) {
                pulse = true
            }
        }
        .modifier(ProgressChangeHandler(
            progress: progress,
            animatedProgress: $animatedProgress
        ))
    }
}

private struct ProgressChangeHandler: ViewModifier {
    let progress: Double
    @Binding var animatedProgress: Double

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .onChange(of: progress) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animatedProgress = progress
                    }
                }
        } else {
            content
                .onChange(of: progress, perform: { newValue in
                    withAnimation(.easeOut(duration: 0.8)) {
                        animatedProgress = newValue
                    }
                })
        }
    }
}

private struct TrendIndicatorView: View {
    let isImproving: Bool
    @State private var isAnimating = false
    private let size: CGFloat = 32

    var body: some View {
        Image("arrow_relative")
            .resizable()
            .renderingMode(.template)
            .frame(width: 46, height: size)
            .foregroundStyle(isImproving ? AppColor.green : AppColor.red)
            .rotationEffect(isImproving ? .zero : .degrees(180))
            .offset(x: isAnimating ? 6 : 0)
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

private struct WellnessMetricRow: View {
    let metric: WellnessMetric

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(metric.tint)
                .frame(width: 8, height: 8)

            Text(metric.title)
                .font(AppFont.body(size: 13, weight: .medium))
                .foregroundStyle(AppColor.black)

            Spacer()

            Text("\(metric.current)")
                .font(AppFont.body(size: 13, weight: .semibold))
                .foregroundStyle(AppColor.grey)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct WellnessDeltaRow: View {
    let metric: WellnessMetric

    var body: some View {
        let diff = metric.current - metric.previous
        let diffColor = diff >= 0 ? AppColor.green : AppColor.red

        return HStack(spacing: 8) {
            Circle()
                .fill(metric.tint)
                .frame(width: 8, height: 8)

            Text(metric.title)
                .font(AppFont.body(size: 13, weight: .medium))
                .foregroundStyle(AppColor.black)

            Spacer()

            Text("\(diff >= 0 ? "+" : "")\(diff)")
                .font(AppFont.body(size: 13, weight: .semibold))
                .foregroundStyle(diffColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct WellnessChangeBadge: View {
    let isImproving: Bool
    let changeValue: Int

    var body: some View {
        HStack(spacing: 8) {
            Image("arrow_relative")
                .resizable()
                .renderingMode(.template)
                .frame(width: 26, height: 20)
                .font(.system(size: 14, weight: .bold))
            Text("\(isImproving ? "+" : "")\(changeValue) points")
                .font(AppFont.body(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background((isImproving ? AppColor.green : AppColor.red).opacity(0.12))
        .foregroundStyle(isImproving ? AppColor.green : AppColor.red)
        .clipShape(Capsule())
    }
}

private struct WellnessScoreCardPreview: View {
    @State private var mode: WellnessMode = .absolute

    var body: some View {
        WellnessScoreCard(
            title: "Wellness Overview",
            description: "Your current wellness level based on activity, sleep, heart health, and nutrition patterns.",
            currentScore: 82,
            previousScore: 74,
            progress: 0.82,
            metrics: [
                WellnessMetric(title: "Activity", current: 78, previous: 71, tint: AppColor.green),
                WellnessMetric(title: "Sleep", current: 85, previous: 80, tint: AppColor.blue),
                WellnessMetric(title: "Heart", current: 72, previous: 75, tint: AppColor.red),
                WellnessMetric(title: "Nutrition", current: 80, previous: 76, tint: AppColor.yellow)
            ],
            isImproving: true,
            changeValue: 8,
            mode: $mode
        )
    }
}

#Preview {
    WellnessScoreCardPreview()
        .padding()
        .background(Color.black.opacity(0.02))
}
