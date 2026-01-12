import Foundation

struct PasswordLoginRequest: Encodable {
    let username: String
    let password: String
    let rememberMe: Bool
}
