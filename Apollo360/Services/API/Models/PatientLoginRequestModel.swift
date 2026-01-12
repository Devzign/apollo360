import Foundation

/// Encodes the request body that is sent to `{{baseURL}}/v1/auth/patient-login`.
struct PatientLoginRequest: Encodable {
    let phone: String
    let dateOfBirth: String
    let deviceId: String
    let trustToken: String
}
