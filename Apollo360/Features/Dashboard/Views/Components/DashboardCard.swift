import SwiftUI

struct DashboardCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppColor.secondary)
                    .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.black.opacity(0.06), lineWidth: 1)
                    )
            )
    }
}

#Preview {
    DashboardCard {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview Title")
                .font(AppFont.display(size: 18, weight: .bold))
                .foregroundStyle(AppColor.black)
            Text("Preview content goes here.")
                .font(AppFont.body(size: 13))
                .foregroundStyle(AppColor.grey)
        }
    }
    .padding()
    .background(Color.black.opacity(0.02))
}
