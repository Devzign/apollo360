import SwiftUI

struct WellnessMetricRow: View {
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

struct WellnessMetricRow_Previews: PreviewProvider {
    static var previews: some View {
        WellnessMetricRow(metric: WellnessMetric(title: "Focus", current: 82, previous: 78, tint: AppColor.blue))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
