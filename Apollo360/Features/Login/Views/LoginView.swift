import SwiftUI
import UIKit

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject private var session: SessionManager
    @State private var isDatePickerPresented: Bool = false

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
                        patientId: response.patientIdentifier,
                        username: response.displayName
                    )
                }
            }
        }
        .sheet(isPresented: $isDatePickerPresented) {
            ZStack {
                Color.white.ignoresSafeArea()
                NavigationStack {
                    VStack(alignment: .leading, spacing: 24) {
                        DatePicker(
                            "Date of Birth",
                            selection: $viewModel.datePickerDate,
                            in: viewModel.dobDateRange,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .onChange(of: viewModel.datePickerDate) { newValue in
                            viewModel.updateDOBFields(from: newValue)
                        }

                        Button("Done") {
                            isDatePickerPresented = false
                        }
                        .buttonStyle(.borderedProminent)
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
            .presentationDetents([.fraction(0.70)])
            .presentationDragIndicator(.visible)
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
                MiniInputField(
                    placeholder: "MM",
                    text: Binding(get: { viewModel.month }, set: viewModel.updateMonth)
                )
                MiniInputField(
                    placeholder: "DD",
                    text: Binding(get: { viewModel.day }, set: viewModel.updateDay)
                )
                MiniInputField(
                    placeholder: "YYYY",
                    text: Binding(get: { viewModel.year }, set: viewModel.updateYear)
                )

                Button {
                    isDatePickerPresented.toggle()
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 44, height: 50)
                        .foregroundStyle(AppColor.green)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(AppColor.green, lineWidth: 1.2)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white))
                        )
                }
                .buttonStyle(.plain)
            }

            if let validationMessage = viewModel.dateValidationMessage {
                Text(validationMessage)
                    .font(AppFont.body(size: 12, weight: .medium))
                    .foregroundStyle(AppColor.red)
            }

            Text("Phone Number")
                .font(AppFont.body(size: 14, weight: .semibold))
                .foregroundStyle(AppColor.black)

            PhoneInputField(
                text: viewModel.formattedPhoneNumber,
                onTextChange: viewModel.updatePhoneNumber
            )
            if let validationMessage = viewModel.phoneValidationMessage {
                Text(validationMessage)
                    .font(AppFont.body(size: 12, weight: .medium))
                    .foregroundStyle(AppColor.red)
            }
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
    let text: String
    let onTextChange: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "phone.fill")
                .foregroundStyle(AppColor.green)
            PhoneNumberTextField(
                displayText: text,
                onTextChange: onTextChange
            )
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
        textField.placeholder = "Enter Your Phone Number"
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
            let limitedDigits = String(digits.prefix(10))
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
