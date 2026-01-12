import Foundation
import UIKit
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var month: String = ""
    @Published var day: String = ""
    @Published var year: String = ""
    @Published private(set) var formattedPhoneNumber: String = ""
    @Published var otpCode: String = ""
    @Published var isLoading: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false

    private var phoneDigits: String = ""

    @Published var isOTPSent: Bool = false
    var onVerifySuccess: ((PatientLoginResponse) -> Void)?

    var isFormValid: Bool {
        !month.trimmingCharacters(in: .whitespaces).isEmpty &&
            !day.trimmingCharacters(in: .whitespaces).isEmpty &&
            !year.trimmingCharacters(in: .whitespaces).isEmpty &&
            phoneDigits.count == 10
    }

    var phoneValidationMessage: String? {
        guard !phoneDigits.isEmpty else { return nil }
        return phoneDigits.count == 10 ? nil : "Enter a 10-digit mobile number."
    }

    func sendOTP() {
        guard isFormValid,
              let dob = formattedDOB else {
            showAlert(title: "Missing information", message: "Please complete every field before continuing.")
            return
        }

        let request = PatientLoginRequest(
            phone: phoneDigits,
            dateOfBirth: dob,
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            trustToken: UUID().uuidString
        )

        isLoading = true
        APIClient.shared.request(endpoint: APIEndpoint.patientLogin,
                                 method: .post,
                                 body: request,
                                 responseType: PatientLoginResponse.self) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.isOTPSent = true
                self.showAlert(title: "Next step", message: response.message ?? "OTP sent successfully.")
            case .failure(let error):
                self.showAlert(title: "Something went wrong", message: error.localizedDescription)
            }
        }
    }

    func verifyOTP() {
        guard isOTPSent else { return }
        guard !otpCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "OTP required", message: "Enter the OTP we sent you.")
            return
        }
        let request = VerifyOTPRequest(
            phone: phoneDigits,
            otp: otpCode.trimmingCharacters(in: .whitespacesAndNewlines),
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            rememberDevice: false
        )
        isLoading = true
        APIClient.shared.verifyOTP(with: request) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.onVerifySuccess?(response)
                self.showAlert(title: "Verified", message: response.message ?? "OTP verified successfully.")
            case .failure(let error):
                self.showAlert(title: "Verification failed", message: error.localizedDescription)
            }
        }
    }

    func updatePhoneNumber(_ raw: String) {
        let digits = raw.filter(\.isNumber)
        let truncated = String(digits.prefix(10))
        phoneDigits = truncated
        formattedPhoneNumber = formatPhoneNumber(truncated)
    }

    private func formatPhoneNumber(_ digits: String) -> String {
        switch digits.count {
        case 0...3:
            return digits
        case 4...6:
            let prefix = String(digits.prefix(3))
            let suffix = String(digits.dropFirst(3))
            return "(\(prefix)) \(suffix)"
        default:
            let prefix = String(digits.prefix(3))
            let mid = String(digits.dropFirst(3).prefix(3))
            let last = String(digits.dropFirst(6))
            return "(\(prefix)) \(mid)-\(last)"
        }
    }

    private var formattedDOB: String? {
        let sanitizedMonth = month.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedDay = day.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedYear = year.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let monthInt = Int(sanitizedMonth), (1...12).contains(monthInt),
            let dayInt = Int(sanitizedDay), (1...31).contains(dayInt),
            let yearInt = Int(sanitizedYear), yearInt >= 1900
        else {
            return nil
        }

        let monthString = String(format: "%02d", monthInt)
        let dayString = String(format: "%02d", dayInt)
        return "\(yearInt)-\(monthString)-\(dayString)"
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
