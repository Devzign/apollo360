import SwiftUI

struct LogoutView: View {
    let logoutAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Click the button below to log out.")
                .font(AppFont.body(size: 15))
                .foregroundColor(AppColor.grey)
                .multilineTextAlignment(.center)

            Button("Logout") {
                logoutAction()
            }
            .font(AppFont.body(size: 15, weight: .semibold))
            .padding(.vertical, 12)
            .padding(.horizontal, 28)
            .background(AppColor.green)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.secondary.ignoresSafeArea())
        .navigationTitle("Logout")
        .navigationBarTitleDisplayMode(.inline)
    }
}
