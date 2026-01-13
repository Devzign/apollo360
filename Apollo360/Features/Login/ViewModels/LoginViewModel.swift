import Foundation
import UIKit
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published private(set) var formattedPhoneNumber: String = ""
    @Published var otpCode: String = ""
    @Published var isLoading: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var alertStyle: AlertStyle = .standard

    private var phoneDigits: String = ""

    @Published var isOTPSent: Bool = false
    var onVerifySuccess: ((PatientLoginResponse) -> Void)?
    @Published var selectedDateOfBirth: Date?
    @Published var datePickerDate: Date = Date()

    private let calendar = Calendar(identifier: .gregorian)

    var dobDateRange: ClosedRange<Date> {
        let start = calendar.date(from: DateComponents(year: 1800, month: 1, day: 1)) ?? Date.distantPast
        return start...Date()
    }

    private static let apiDOBFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private static let displayDOBFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    var dateOfBirthDisplayText: String {
        guard let dob = selectedDateOfBirth else { return "" }
        return Self.displayDOBFormatter.string(from: dob)
    }

    var isFormValid: Bool {
        phoneDigits.count == 10 && selectedDateOfBirth != nil
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
                self.showAlert(title: "Something went wrong", message: error.localizedDescription, style: .error)
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
                if let user = response.user {
                    self.showAlert(title: "Welcome \(user.firstName)", message: "Logged in as \(user.username).")
                } else {
                    self.showAlert(title: "Verified", message: response.message ?? "OTP verified successfully.")
                }
            case .failure(let error):
                self.showAlert(title: "Verification failed", message: error.localizedDescription, style: .error)
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
        guard let dob = selectedDateOfBirth else { return nil }
        return Self.apiDOBFormatter.string(from: dob)
    }

    func updateDOBFields(from date: Date) {
        selectedDateOfBirth = date
        datePickerDate = date
    }

    private func showAlert(title: String, message: String, style: AlertStyle = .standard) {
        alertTitle = title
        alertMessage = message
        alertStyle = style
        showAlert = true
    }
}
