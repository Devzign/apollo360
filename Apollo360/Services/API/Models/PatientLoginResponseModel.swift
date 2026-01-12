import Foundation

struct PatientLoginResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let userId: String?
    let message: String?
}
