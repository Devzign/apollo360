import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel: NotificationsViewModel

    init(session: SessionManager) {
        _viewModel = StateObject(
            wrappedValue: NotificationsViewModel(session: session)
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                Text("Notification Setting")
                    .font(AppFont.display(size: 32, weight: .semibold))
                    .foregroundColor(AppColor.color414141)

                VStack(spacing: 16) {
                    notificationRow(
                        title: "Push Notifications",
                        description: "Receive instant app notifications.",
                        isOn: Binding(
                            get: { viewModel.pushNotifications },
                            set: { viewModel.updatePushNotifications($0) }
                        )
                    )
                    notificationRow(
                        title: "Text Messages",
                        description: "Receive updates by SMS.",
                        isOn: Binding(
                            get: { viewModel.textMessages },
                            set: { viewModel.updateTextMessages($0) }
                        )
                    )
                    notificationRow(
                        title: "Emails",
                        description: "Receive updates by email.",
                        isOn: Binding(
                            get: { viewModel.emails },
                            set: { viewModel.updateEmails($0) }
                        )
                    )
                }
                .padding(.horizontal, 4)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.08).ignoresSafeArea()
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            }
        )
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationTitle("Notification Setting")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadSettings()
        }
        .alert(isPresented: Binding(
            get: { viewModel.alertMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.clearAlert()
                }
            }
        )) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage ?? ""),
                dismissButton: .cancel(Text("OK")) {
                    viewModel.clearAlert()
                }
            )
        }
    }

    private func notificationRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.color414141)
                Text(description)
                    .font(AppFont.body(size: 13))
                    .foregroundColor(AppColor.grey)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: AppColor.green))
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
        )
    }
}

#if DEBUG
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationsView(session: SessionManager())
        }
        .previewDisplayName("Notification Settings")
    }
}
#endif
