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
    @Published var datePickerDate: Date = Date()

    private let calendar = Calendar(identifier: .gregorian)

    var dobDateRange: ClosedRange<Date> {
        let start = calendar.date(from: DateComponents(year: 1800, month: 1, day: 1)) ?? Date.distantPast
        return start...Date()
    }

    var dateValidationMessage: String? {
        guard hasAnyDateInput else { return nil }
        return sanitizedDOBComponents == nil
            ? "Enter a valid date between 01/01/1800 and today."
            : nil
    }

    private var hasAnyDateInput: Bool {
        !month.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !day.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !year.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var currentYear: Int {
        calendar.component(.year, from: Date())
    }

    func updateMonth(_ raw: String) {
        let digits = restrictDigits(raw, limit: 2)
        month = clampDigits(digits, limit: 2, range: 1...12)
    }

    func updateDay(_ raw: String) {
        let digits = restrictDigits(raw, limit: 2)
        day = clampDigits(digits, limit: 2, range: 1...31)
    }

    func updateYear(_ raw: String) {
        let digits = restrictDigits(raw, limit: 4)
        year = clampDigits(digits, limit: 4, range: 1800...currentYear)
    }

    private func restrictDigits(_ raw: String, limit: Int) -> String {
        let digits = raw.filter(\.isNumber)
        return String(digits.prefix(limit))
    }

    private func clampDigits(_ digits: String, limit: Int, range: ClosedRange<Int>) -> String {
        guard digits.count == limit, let value = Int(digits) else { return digits }
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return String(format: "%0\(limit)d", clamped)
    }
    var isFormValid: Bool {
        phoneDigits.count == 10 && formattedDOB != nil
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
                if let user = response.user {
                    self.showAlert(title: "Welcome \(user.firstName)", message: "Logged in as \(user.username).")
                } else {
                    self.showAlert(title: "Verified", message: response.message ?? "OTP verified successfully.")
                }
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
        guard let components = sanitizedDOBComponents,
              let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private var sanitizedDOBComponents: DateComponents? {
        let sanitizedMonth = month.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedDay = day.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitizedYear = year.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            let monthInt = Int(sanitizedMonth), (1...12).contains(monthInt),
            let dayInt = Int(sanitizedDay), (1...31).contains(dayInt),
            let yearInt = Int(sanitizedYear),
            (1800...calendar.component(.year, from: Date())).contains(yearInt)
        else {
            return nil
        }

        let components = DateComponents(year: yearInt, month: monthInt, day: dayInt)
        guard let date = calendar.date(from: components), date <= Date() else {
            return nil
        }
        return components
    }

    func updateDOBFields(from date: Date) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let monthValue = components.month,
              let dayValue = components.day,
              let yearValue = components.year else { return }
        month = String(format: "%02d", monthValue)
        day = String(format: "%02d", dayValue)
        year = String(format: "%04d", yearValue)
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
