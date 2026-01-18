//
//  ScoreBreakdownView.swift
//  Apollo360
//
//  Created by Codex on 11/01/26.
//

import SwiftUI

struct ScoreBreakdownView: View {
    let score: Int
    let mode: WellnessMode
    let metrics: [WellnessMetric]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Score Breakdown")
                    .font(AppFont.display(size: 20, weight: .bold))
                    .foregroundStyle(AppColor.black)

                Text("Mode: \(mode.rawValue.capitalized)")
                    .font(AppFont.body(size: 14, weight: .medium))
                    .foregroundStyle(AppColor.grey)

                ZStack {
                    Circle()
                        .stroke(AppColor.grey.opacity(0.3), lineWidth: 12)
                        .frame(width: 140, height: 140)
                    Circle()
                        .trim(from: 0, to: min(Double(score) / 100.0, 1))
                        .stroke(AppColor.green, lineWidth: 12)
                        .rotationEffect(.degrees(-90))
                        .frame(width: 140, height: 140)
                    Text("\(score)")
                        .font(AppFont.display(size: 40, weight: .bold))
                        .foregroundStyle(AppColor.black)
                }

                Text("You are a very healthy individual.")
                    .font(AppFont.body(size: 14))
                    .foregroundStyle(AppColor.grey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(metrics) { metric in
                        HStack {
                            Text(metric.title)
                                .font(AppFont.body(size: 16, weight: .medium))
                                .foregroundStyle(AppColor.black)
                            Spacer()
                            Text("\(metric.current)")
                                .font(AppFont.display(size: 20, weight: .bold))
                                .foregroundStyle(AppColor.green)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 4)
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemBackground).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EmptyView()
                }
                ToolbarItem(placement: .principal) {
                    Text("Score Breakdown")
                        .font(AppFont.body(size: 16, weight: .semibold))
                        .foregroundStyle(AppColor.black)
                }
            }
        }
    }
}

#Preview {
    ScoreBreakdownView(
        score: 74,
        mode: .absolute,
        metrics: [
            WellnessMetric(title: "Activity", current: 67, previous: 60, tint: AppColor.green),
            WellnessMetric(title: "Sleep", current: 88, previous: 80, tint: AppColor.blue),
            WellnessMetric(title: "Heart", current: 63, previous: 66, tint: AppColor.red),
            WellnessMetric(title: "Nutrition", current: 77, previous: 70, tint: AppColor.yellow),
        ]
    )
}
