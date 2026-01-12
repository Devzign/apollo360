import Foundation

/// Request payload for OTP verification.
struct VerifyOTPRequest: Encodable {
    let phone: String
    let otp: String
    let deviceId: String
    let rememberDevice: Bool
}
