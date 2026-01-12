import Foundation

/// Represents the shape of the response returned by the patient login endpoint.
/// Update the properties below once the actual API contract is available.
struct PatientLoginResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let userId: String?
    let message: String?
}
