import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        NavigationStack {
            AuthShell {
                VStack(spacing: 24) {
                    formFields

                    if viewModel.isOTPSent {
                        otpInput
                    }

                    actionButton

                    NavigationLink(destination: PasswordLoginView().environmentObject(session)) {
                        Text("Use username & password login")
                            .font(AppFont.body(size: 14, weight: .medium))
                            .foregroundStyle(AppColor.green)
                    }
                    .padding(.top, 6)
                }
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { viewModel.showAlert = false }
        } message: {
            Text(viewModel.alertMessage)
        }
        .onAppear {
            if viewModel.onVerifySuccess == nil {
                viewModel.onVerifySuccess = { response in
                    session.updateSession(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken,
                        patientId: response.userId,
                        username: nil
                    )
                }
            }
        }
    }

    private var formFields: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Welcome to Apollo!")
                .font(AppFont.display(size: 26, weight: .bold))
                .foregroundStyle(AppColor.green)

            Text("Date Of Birth")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.black)

            HStack(spacing: 12) {
                MiniInputField(placeholder: "MM", text: $viewModel.month)
                MiniInputField(placeholder: "DD", text: $viewModel.day)
                MiniInputField(placeholder: "YYYY", text: $viewModel.year)
            }

            Text("Phone Number")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.black)

            PhoneInputField(
                text: Binding(
                    get: { viewModel.formattedPhoneNumber },
                    set: { viewModel.updatePhoneNumber($0) }
                )
            )
        }
    }

    private var otpInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OTP")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.black)
            OTPInputField(text: $viewModel.otpCode)
        }
    }

    private var actionButton: some View {
        Button {
            if viewModel.isOTPSent {
                viewModel.verifyOTP()
            } else {
                viewModel.sendOTP()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColor.green)
                    .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 10)

                Text(viewModel.isOTPSent ? "Verify OTP" : "Send OTP")
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 56)
        }
        .disabled(viewModel.isLoading)
    }
}

private struct MiniInputField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(AppFont.body(size: 16, weight: .medium))
            .foregroundStyle(AppColor.black)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.gray.opacity(0.35), lineWidth: 1.2)
            )
    }
}

private struct PhoneInputField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "phone.fill")
                .foregroundStyle(AppColor.green)
            TextField("Enter Your Phone Number", text: $text)
                .font(AppFont.body(size: 16, weight: .medium))
                .keyboardType(.phonePad)
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.gray.opacity(0.35), lineWidth: 1.2)
        )
    }
}

private struct OTPInputField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .foregroundStyle(AppColor.green)
            TextField("Enter Your OTP", text: $text)
                .font(AppFont.body(size: 16, weight: .medium))
                .keyboardType(.numberPad)
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(SessionManager())
}
