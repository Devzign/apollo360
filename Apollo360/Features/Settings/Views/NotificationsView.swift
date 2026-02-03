import SwiftUI

struct NotificationsView: View {
    @AppStorage("notifications.trackingUpdates") private var trackingUpdates = true
    @AppStorage("notifications.stock") private var stockNotifications = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Notification Setting")
                    .font(AppFont.display(size: 32, weight: .semibold))
                    .foregroundStyle(AppColor.color414141)

                VStack(spacing: 16) {
                    notificationRow(
                        title: "Tracking Updates",
                        description: "Get updates on your order.",
                        isOn: $trackingUpdates
                    )
                    notificationRow(
                        title: "Appointment Alerts",
                        description: "Receive reminders before visits.",
                        isOn: $stockNotifications
                    )
                }
                .padding(.horizontal, 4)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationTitle("Notification Setting")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func notificationRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundStyle(AppColor.color414141)
                Text(description)
                    .font(AppFont.body(size: 13))
                    .foregroundStyle(AppColor.grey)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }
}

#Preview("Notification Settings") {
    NavigationStack {
        NotificationsView()
    }
}
