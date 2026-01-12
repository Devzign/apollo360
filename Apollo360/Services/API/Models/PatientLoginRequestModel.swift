import Foundation

struct PatientLoginRequest: Encodable {
    let phone: String
    let dateOfBirth: String
    let deviceId: String
    let trustToken: String
}
