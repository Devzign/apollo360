//
//  CaregiverLoginView.swift
//  Apollo360
//

import SwiftUI
import Combine

struct CaregiverLoginView: View {
    @StateObject private var viewModel = CaregiverLoginViewModel()
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        AuthShell {
            VStack(spacing: 16) {
                Text("Caregiver Sign In")
                    .font(AppFont.display(size: 26, weight: .bold))
                    .foregroundColor(AppColor.green)

                CaregiverCredentialField(title: "Email", placeholder: "Email", text: $viewModel.email)
                CaregiverCredentialField(title: "Verification Token", placeholder: "Token from email link", text: $viewModel.token)

                HStack(spacing: 10) {
                    Button("Send Link") { viewModel.sendEmailVerificationLink() }
                    Button("Verify") { viewModel.verifyEmailToken() }
                }
                .font(AppFont.body(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().padding(.vertical, 4)

                CaregiverPhoneInputField(
                    text: viewModel.formattedPhoneNumber,
                    onTextChange: viewModel.updatePhoneNumber
                )

                if viewModel.isOTPSent {
                    CaregiverOTPInputField(text: $viewModel.otpCode)
                }

                Button(action: {
                    if viewModel.isOTPSent {
                        viewModel.verifyOTP()
                    } else {
                        viewModel.sendCaregiverOTP()
                    }
                }) {
                    Text(viewModel.isOTPSent ? "Verify OTP" : "Send OTP")
                        .font(AppFont.body(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(AppColor.green)
                )
                .disabled(viewModel.isLoading)
            }
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            if viewModel.onVerifySuccess == nil {
                viewModel.onVerifySuccess = { response in
                    session.updateSession(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken,
                        patientId: response.patientIdentifier,
                        a360Id: response.a360Id,
                        username: response.user?.username,
                        role: response.user?.role ?? "caregiver",
                        careGiverKey: response.user?.careGiverKey,
                        permissions: response.user?.permissions ?? []
                    )
                }
            }
        }
    }
}

#if DEBUG
struct CaregiverLoginView_Previews: PreviewProvider {
    static var previews: some View {
        CaregiverLoginView()
            .environmentObject(SessionManager())
    }
}
#endif

private struct CaregiverCredentialField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.black)

            TextField(placeholder, text: $text)
                .font(AppFont.body(size: 16, weight: .medium))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.2)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                )
        }
    }
}

private struct CaregiverPhoneInputField: View {
    let text: String
    let onTextChange: (String) -> Void

    var body: some View {
        TextField("(xxx) xxx-xxxx", text: Binding(get: { text }, set: onTextChange))
            .keyboardType(.phonePad)
            .font(AppFont.body(size: 16, weight: .medium))
            .padding(.horizontal, 18)
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.gray.opacity(0.35), lineWidth: 1.2)
            )
    }
}

private struct CaregiverOTPInputField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OTP")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.black)

            TextField("Enter OTP", text: $text)
                .keyboardType(.numberPad)
                .font(AppFont.body(size: 16, weight: .medium))
                .padding(.horizontal, 16)
                .frame(height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.gray.opacity(0.35), lineWidth: 1.2)
                )
        }
    }
}
