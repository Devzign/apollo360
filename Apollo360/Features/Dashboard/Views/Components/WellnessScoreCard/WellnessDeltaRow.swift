import SwiftUI

struct WellnessDeltaRow: View {
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

struct WellnessDeltaRow_Previews: PreviewProvider {
    static var previews: some View {
        WellnessDeltaRow(metric: WellnessMetric(title: "Sleep", current: 85, previous: 78, tint: AppColor.green))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
