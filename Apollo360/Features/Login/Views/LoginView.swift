//
//  LoginView.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import SwiftUI
import UIKit

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var session: SessionManager
    @State private var isDatePickerPresented: Bool = false
    @State private var didAttemptBiometricUnlock: Bool = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var cardMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 520 : 380
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColor.green.ignoresSafeArea()

                VStack {
                    Spacer()
                        .frame(height: 64)
                    Image("apolloLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .padding(.bottom, 16)
                    Spacer()
                    loginCard
                    Spacer()
                        .frame(height: 32)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $isDatePickerPresented) {
            ZStack {
                Color.white.ignoresSafeArea()
                NavigationView {
                    VStack(alignment: .leading, spacing: 24) {
                        DatePicker(
                            "Date of Birth",
                            selection: $viewModel.datePickerDate,
                            in: viewModel.dobDateRange,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .environment(\.locale, Locale(identifier: "en_US_POSIX"))
                        .labelsHidden()
                        .frame(maxWidth: .infinity)

                        Button("Done") {
                            viewModel.updateDOBFields(from: viewModel.datePickerDate)
                            isDatePickerPresented = false
                        }
                        .font(AppFont.body(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppColor.green)
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .navigationTitle("Select date")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isDatePickerPresented = false
                            }
                        }
                    }
                }
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
            if viewModel.onVerifySuccess == nil {
                viewModel.onVerifySuccess = { response in
                    session.updateSession(
                        accessToken: response.accessToken,
                        refreshToken: response.refreshToken,
                        patientId: response.patientIdentifier,
                        a360Id: response.a360Id,
                        username: response.user?.username
                    )
                }
            }
            viewModel.configureFaceIDSelection(for: session.patientId)
            if session.requiresBiometricUnlock && !didAttemptBiometricUnlock {
                didAttemptBiometricUnlock = true
                attemptBiometricLogin()
            }
        }
    }

    private var loginCard: some View {
        VStack(spacing: 22) {
            VStack(spacing: 4) {
                Text("Sign In")
                    .font(AppFont.display(size: 32, weight: .bold))
                    .foregroundColor(AppColor.black)

                Text("Enter your Sign In details")
                    .font(AppFont.body(size: 14))
                    .foregroundColor(AppColor.grey)
            }

            formFields

            if viewModel.isOTPSent {
                otpInput
                faceIDPreferenceCheckbox
            }

            actionButton

            if session.requiresBiometricUnlock {
                faceIDLoginButton
            }

//            NavigationLink(destination: CaregiverLoginView().environmentObject(session)) {
//                HStack(spacing: 2) {
//                    Text("Caregiver")
//                        .font(AppFont.body(size: 14, weight: .medium))
//                        .foregroundColor(AppColor.black)
//                    Text(" Log-In")
//                        .font(AppFont.body(size: 14, weight: .medium))
//                        .foregroundColor(AppColor.green)
//                }
//            }
//            .padding(.top, 8)

            NavigationLink(destination: PasswordLoginView().environmentObject(session)) {
                HStack(spacing: 2) {
                    Text("Password")
                        .font(AppFont.body(size: 14, weight: .medium))
                        .foregroundColor(AppColor.black)
                    Text(" Log-In")
                        .font(AppFont.body(size: 14, weight: .medium))
                        .foregroundColor(AppColor.green)
                }
            }
        }
        .padding(30)
        .frame(maxWidth: cardMaxWidth)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 12)
        )
        .padding(.horizontal, 24)
    }

    private var formFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date of Birth")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.black)

            HStack(spacing: 12) {
                TextField("MM-DD-YYYY", text: $viewModel.dateOfBirthText)
                .font(AppFont.body(size: 16, weight: .medium))
                .keyboardType(.numberPad)
                .textContentType(.none)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .frame(maxWidth: .infinity)
                .onChange(of: viewModel.dateOfBirthText) { newValue in
                    viewModel.updateDateOfBirthText(newValue)
                }

                Button {
                    viewModel.datePickerDate = viewModel.selectedDateOfBirth ?? Date()
                    isDatePickerPresented = true
                } label: {
                    Image("calendar_icon")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(
                            viewModel.selectedDateOfBirth == nil ? Color.gray.opacity(0.7) : AppColor.green
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.gray.opacity(0.35), lineWidth: 1.2)
            )

            Text("Phone Number")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.black)

            PhoneInputField(
                text: viewModel.formattedPhoneNumber,
                onTextChange: viewModel.updatePhoneNumber
            )

            if let validationMessage = viewModel.phoneValidationMessage {
                Text(validationMessage)
                    .font(AppFont.body(size: 12, weight: .medium))
                    .foregroundColor(AppColor.red)
            }
        }
    }

    private var otpInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("OTP")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundColor(AppColor.black)
            OTPInputField(text: $viewModel.otpCode)
        }
        .padding(.top, 6)
    }

    private var faceIDPreferenceCheckbox: some View {
        Group {
            if viewModel.canUseBiometrics {
                Toggle(isOn: $viewModel.faceIdEnabled) {
                    Text("Enable Face ID on this device")
                        .font(AppFont.body(size: 14))
                        .foregroundColor(AppColor.black)
                }
                .toggleStyle(FaceIDCheckboxToggleStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
            }
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

                Text(viewModel.isOTPSent ? "Verify OTP" : "Sign In")
                    .font(AppFont.body(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 56)
        }
        .disabled(viewModel.isLoading)
    }

    private var faceIDLoginButton: some View {
        Button(action: attemptBiometricLogin) {
            Label("Login with Face ID", systemImage: "faceid")
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.green)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColor.green, lineWidth: 1.2)
                )
        }
        .padding(.top, 4)
    }

    private func attemptBiometricLogin() {
        session.unlockWithBiometrics { result in
            if case .failure(let error) = result {
                viewModel.showBiometricError(error.localizedDescription)
            }
        }
    }
}

private struct FaceIDCheckboxToggleStyle: ToggleStyle {
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

private struct PhoneInputField: View {
    let text: String
    let onTextChange: (String) -> Void

    var body: some View {
        PhoneNumberTextField(
            displayText: text,
            onTextChange: onTextChange
        )
        .padding(.horizontal, 18)
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.gray.opacity(0.35), lineWidth: 1.2)
        )
    }
}

private struct PhoneNumberTextField: UIViewRepresentable {
    let displayText: String
    let onTextChange: (String) -> Void

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .phonePad
        textField.textContentType = .telephoneNumber
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textField.placeholder = "(xxx) xxx-xxxx"
        textField.delegate = context.coordinator
        textField.text = displayText
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != displayText {
            uiView.text = displayText
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: PhoneNumberTextField

        init(_ parent: PhoneNumberTextField) {
            self.parent = parent
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            let nsText = currentText as NSString
            let updated = nsText.replacingCharacters(in: range, with: string)
            let digits = updated.filter(\.isNumber)
            // Pass up to 11 digits so the ViewModel can detect and strip the US +1 country code.
            let limitedDigits = String(digits.prefix(11))
            parent.onTextChange(limitedDigits)
            let endPosition = textField.endOfDocument
            if let newRange = textField.textRange(from: endPosition, to: endPosition) {
                textField.selectedTextRange = newRange
            }
            return false
        }
    }
}

private struct OTPInputField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(AppColor.green)
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(SessionManager())
    }
}
