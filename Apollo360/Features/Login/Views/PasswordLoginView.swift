import SwiftUI

struct PasswordLoginView: View {
    @StateObject private var viewModel = PasswordLoginViewModel()
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        AuthShell {
            VStack(spacing: 22) {
                Text("Welcome back!")
                    .font(AppFont.display(size: 26, weight: .bold))
                    .foregroundStyle(AppColor.green)

                CredentialField(title: "Username", placeholder: "Username", text: $viewModel.username)
                CredentialField(title: "Password", placeholder: "Password", text: $viewModel.password, isSecure: true)

                Toggle(isOn: $viewModel.rememberMe) {
                    Text("Remember me")
                        .font(AppFont.body(size: 14))
                        .foregroundStyle(AppColor.black)
                }
                .toggleStyle(CheckboxToggleStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

                Button(action: viewModel.login) {
                    Text("Sign In")
                        .font(AppFont.body(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(AppColor.green)
                        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
                )
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { viewModel.showAlert = false }
        } message: {
            Text(viewModel.alertMessage)
                .foregroundStyle(viewModel.alertStyle == .error ? AppColor.red : AppColor.black)
        }
        .onAppear {
            if viewModel.onLoginSuccess == nil {
                viewModel.onLoginSuccess = { response in
                    session.updateSession(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken,
                        patientId: "\(response.user.id)",
                        username: "\(response.user.firstName) \(response.user.lastName)"
                    )
                }
            }
        }
    }
}

private struct CredentialField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.black)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(AppFont.body(size: 16, weight: .medium))
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.2)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            )
        }
    }
}

private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundStyle(configuration.isOn ? AppColor.green : Color.gray)
                configuration.label
            }
        }
    }
}

#Preview {
    PasswordLoginView()
}
