//
//  RingDesignCardView.swift
//  Apollo360
//
//  Created by Amit Sinha on 20/01/26.
//

import SwiftUI
import SwiftUIAnimatedRingCharts

struct WellnessRingCircleView: View {

    let metrics: [WellnessMetric]
    let overallScore: Int

    var body: some View {
        ZStack {

            RingChartsView(
                values: metrics.map { CGFloat($0.current) },
                colors: metrics.map { [$0.tint.opacity(0.7), $0.tint] },
                ringsMaxValue: 100,
                isAnimated: true
            )
            .id(overallScore)
            .frame(width: 220, height: 220)
            .background(.clear)

            VStack(spacing: 4) {
                Text("\(overallScore)")
                    .font(AppFont.display(size: 36, weight: .bold))
                    .foregroundStyle(AppColor.black)

                Text("Overall Score")
                    .font(AppFont.body(size: 12, weight: .medium))
                    .foregroundStyle(AppColor.grey)
            }
        }
    }
}

struct WellnessRingCircleView_Previews: PreviewProvider {
    static var previews: some View {
        WellnessRingCircleView(
            metrics: [
                WellnessMetric(title: "Activity", current: 83, previous: 71, tint: .green),
                WellnessMetric(title: "Sleep", current: 84, previous: 80, tint: .blue),
                WellnessMetric(title: "Heart", current: 66, previous: 75, tint: .red),
                WellnessMetric(title: "Nutrition", current: 81, previous: 76, tint: .yellow)
            ],
            overallScore: 79
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewLayout(.sizeThatFits)
    }
}

