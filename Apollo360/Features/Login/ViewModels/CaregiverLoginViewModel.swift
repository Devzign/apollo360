//
//  CaregiverLoginViewModel.swift
//  Apollo360
//

import Foundation
import UIKit
import Combine

@MainActor
final class CaregiverLoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var token: String = ""
    @Published private(set) var formattedPhoneNumber: String = ""
    @Published var otpCode: String = ""

    @Published var isLoading = false
    @Published var isEmailVerified = false
    @Published var isOTPSent = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    private var phoneDigits: String = ""
    var onVerifySuccess: ((PatientLoginResponse) -> Void)?

    func updatePhoneNumber(_ raw: String) {
        let digits = raw.filter(\.isNumber)
        let truncated = String(digits.prefix(10))
        phoneDigits = truncated
        switch truncated.count {
        case 0...3:
            formattedPhoneNumber = truncated
        case 4...6:
            formattedPhoneNumber = "(\(truncated.prefix(3))) \(truncated.dropFirst(3))"
        default:
            let a = truncated.prefix(3)
            let b = truncated.dropFirst(3).prefix(3)
            let c = truncated.dropFirst(6)
            formattedPhoneNumber = "(\(a)) \(b)-\(c)"
        }
    }

    func sendEmailVerificationLink() {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            show("Missing Email", "Please enter your caregiver email.")
            return
        }

        isLoading = true
        APIClient.shared.caregiverSendEmail(with: CaregiverEmailRequest(email: email.trimmingCharacters(in: .whitespacesAndNewlines))) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.show("Verification Link Sent", response.message ?? "Please check your email for the verification link.")
            case .failure(let error):
                self.show("Request Failed", error.localizedDescription)
            }
        }
    }

    func verifyEmailToken() {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            show("Missing Information", "Please enter both email and token.")
            return
        }

        isLoading = true
        APIClient.shared.caregiverVerifyEmail(with: CaregiverVerifyEmailRequest(token: token.trimmingCharacters(in: .whitespacesAndNewlines), email: email.trimmingCharacters(in: .whitespacesAndNewlines))) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.isEmailVerified = true
                self.show("Verified", response.message ?? "Email verified successfully.")
            case .failure(let error):
                self.show("Verification Failed", error.localizedDescription)
            }
        }
    }

    func sendCaregiverOTP() {
        guard isEmailVerified else {
            show("Verify Email First", "Please verify your email/token first.")
            return
        }
        guard phoneDigits.count == 10 else {
            show("Invalid Phone", "Please enter a 10-digit phone number.")
            return
        }

        isLoading = true
        let payload = CaregiverLoginRequest(phone: "1\(phoneDigits)", token: token.trimmingCharacters(in: .whitespacesAndNewlines))
        APIClient.shared.caregiverLogin(with: payload) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.isOTPSent = response.requiresOtp ?? true
                self.show("OTP Sent", response.message ?? "Please enter the OTP sent to your phone.")
            case .failure(let error):
                self.show("Failed", error.localizedDescription)
            }
        }
    }

    func verifyOTP() {
        guard isOTPSent else { return }
        let otp = otpCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard otp.count >= 4 else {
            show("OTP Required", "Please enter the OTP.")
            return
        }
        isLoading = true
        let request = VerifyOTPRequest(
            phone: "1\(phoneDigits)",
            otp: otp,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            rememberDevice: true,
            role: "caregiver"
        )
        APIClient.shared.verifyOTP(with: request) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.onVerifySuccess?(response)
                self.show("Welcome", response.message ?? "Caregiver logged in.")
            case .failure(let error):
                self.show("Verification Failed", error.localizedDescription)
            }
        }
    }

    private func show(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
