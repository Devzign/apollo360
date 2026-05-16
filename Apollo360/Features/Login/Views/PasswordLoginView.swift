//
//  PasswordLoginView.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI

struct PasswordLoginView: View {
    @StateObject private var viewModel = PasswordLoginViewModel()
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        AuthShell {
            VStack(spacing: 22) {
                Text("Welcome back!")
                    .font(AppFont.display(size: 26, weight: .bold))
                    .foregroundColor(AppColor.green)

                CredentialField(title: "Username", placeholder: "Username", text: $viewModel.username)
                CredentialField(title: "Password", placeholder: "Password", text: $viewModel.password, isSecure: true)

                Toggle(isOn: $viewModel.rememberMe) {
                    Text("Remember me")
                        .font(AppFont.body(size: 14))
                        .foregroundColor(AppColor.black)
                }
                .toggleStyle(CheckboxToggleStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

                if viewModel.canUseBiometrics {
                    Toggle(isOn: $viewModel.faceIdEnabled) {
                        Text("Enable Face ID on this device")
                            .font(AppFont.body(size: 14))
                            .foregroundColor(AppColor.black)
                    }
                    .toggleStyle(CheckboxToggleStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: viewModel.login) {
                    Text("Sign In")
                        .font(AppFont.body(size: 18, weight: .semibold))
                        .foregroundColor(.white)
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
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .cancel(Text("OK")) {
                    viewModel.showAlert = false
                }
            )
        }
        .onAppear {
            viewModel.configureFaceIDSelection(for: session.patientId)
            if viewModel.onLoginSuccess == nil {
                viewModel.onLoginSuccess = { response in
                    session.updateSession(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken,
                        patientId: response.patientId,
                        a360Id: response.a360Id,
                        username: response.user.username,
                        role: nil,
                        careGiverKey: nil,
                        permissions: []
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
                .foregroundColor(AppColor.black)

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
                    .foregroundColor(configuration.isOn ? AppColor.green : Color.gray)
                configuration.label
            }
        }
    }
}

#if DEBUG
struct PasswordLoginView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordLoginView()
    }
}
#endif
