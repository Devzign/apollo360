import Foundation

struct PasswordLoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: UserInfo

    struct UserInfo: Decodable {
        let id: Int
        let email: String
        let username: String
        let firstName: String
        let lastName: String
    }
}
