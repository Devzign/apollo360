import SwiftUI

struct DashboardHeaderView: View {
    let greeting: String
    let userName: String

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(AppFont.body(size: 14))
                    .foregroundStyle(AppColor.grey)
                Text(userName)
                    .font(AppFont.display(size: 22, weight: .semibold))
                    .foregroundStyle(AppColor.black)
            }
            Spacer()
            HStack(spacing: 12) {
                Button(action: {}) {
                    HeaderIconButton(systemImage: "bell", showsBadge: true)
                }
                Button(action: {}) {
                    HeaderIconButton(systemImage: "gearshape", showsBadge: false)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(AppColor.secondary)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.black.opacity(0.08)),
            alignment: .bottom
        )
    }
}

private struct HeaderIconButton: View {
    let systemImage: String
    let showsBadge: Bool

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(AppColor.colorECF0F3)
                .frame(width: 40, height: 40)

            // Centered icon
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(AppColor.black)

            // Badge only
            if showsBadge {
                Circle()
                    .fill(AppColor.red)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(AppColor.secondary, lineWidth: 2)
                    )
                    .offset(x: 12, y: -12)
            }
        }
        .frame(width: 40, height: 40)
    }
}


#Preview {
    DashboardHeaderView(greeting: "Good morning,", userName: "Amit Sinha")
}
