import SwiftUI

func metricsInfoCard(title: String, message: String, dismiss: @escaping () -> Void) -> some View {
    HStack(alignment: .top, spacing: 14) {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.green.opacity(0.85))

            Text(message)
                .font(AppFont.body(size: 14))
                .foregroundColor(AppColor.green.opacity(0.72))
                .lineSpacing(2)
        }

        Spacer(minLength: 8)

        Button(action: dismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColor.green.opacity(0.7))
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
    }
    .padding(18)
    .background(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color(red: 227 / 255, green: 241 / 255, blue: 226 / 255))
    )
}

var metricsPageBackgroundView: some View {
    LinearGradient(
        colors: [
            Color(red: 247 / 255, green: 250 / 255, blue: 246 / 255),
            Color(red: 241 / 255, green: 247 / 255, blue: 241 / 255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
