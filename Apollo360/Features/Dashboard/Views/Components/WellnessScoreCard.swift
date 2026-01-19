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
    @State private var wavePhase: Double = 0
    @State private var isBumping = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.44, blue: 0.95),
                            Color(red: 0.59, green: 0.8, blue: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 6
                )

            WaveContainerView(progress: animatedProgress, phase: wavePhase)
                .clipShape(Circle())
                .padding(14)

            Circle()
                .stroke(Color.white.opacity(0.4), lineWidth: 2)

            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(score)")
                        .font(AppFont.display(size: 46, weight: .bold))
                    Text("%")
                        .font(AppFont.body(size: 20, weight: .bold))
                        .baselineOffset(8)
                }

                Text("Overall Score")
                    .font(AppFont.body(size: 13))
                    .foregroundStyle(AppColor.white)
                Text("Body energy \(score)%")
                    .font(AppFont.body(size: 12, weight: .semibold))
                    .foregroundStyle(AppColor.grey)
            }
            .foregroundStyle(AppColor.black)
        }
        .frame(width: 220, height: 220)
        .padding(.vertical, 16)
        .contentShape(Circle())
        .scaleEffect(isBumping ? 1.02 : 1)
        .animation(
            .easeInOut(duration: 1.4).repeatForever(autoreverses: true),
            value: isBumping
        )
        .onTapGesture {
            onTap?()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animatedProgress = progress
            }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                wavePhase = 1
            }
            isBumping = true
        }
        .modifier(ProgressChangeHandler(
            progress: progress,
            animatedProgress: $animatedProgress
        ))
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

private struct WaveShape: Shape {
    var progress: Double
    var phase: Double
    var amplitude: CGFloat
    var frequency: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let normalizedProgress = max(0, min(1, progress))
        let baseY = height * CGFloat(1 - normalizedProgress)

        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: baseY))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let angle = (relativeX * frequency + phase) * .pi * 2
            let y = baseY + sin(angle) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()

        return path
    }
}

private struct WaveContainerView: View {
    var progress: Double
    var phase: Double

    private var fillGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.11, green: 0.46, blue: 0.92),
                Color(red: 0.18, green: 0.57, blue: 0.94),
                Color(red: 0.11, green: 0.38, blue: 0.76)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white.opacity(0.1)

                WaveShape(progress: progress, phase: phase, amplitude: 18, frequency: 1.4)
                    .fill(fillGradient)
                    .clipped()

                WaveShape(progress: max(0, min(1, progress - 0.07)), phase: phase - 0.4, amplitude: 12, frequency: 1.9)
                    .fill(Color.white.opacity(0.3))

                Circle()
                    .stroke(Color.white.opacity(0.45), lineWidth: 2)
                    .frame(width: geo.size.width * 0.12, height: geo.size.width * 0.12)
                    .offset(
                        x: -geo.size.width * 0.08 + geo.size.width * 0.12 * sin(phase * .pi * 2),
                        y: -geo.size.height * 0.15 + geo.size.height * 0.05 * cos(phase * .pi * 2)
                    )
                    .blendMode(.screen)

                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: geo.size.width * 0.08, height: geo.size.width * 0.08)
                    .offset(x: geo.size.width * 0.22, y: -geo.size.height * 0.1)
                    .blur(radius: 0.6)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
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
