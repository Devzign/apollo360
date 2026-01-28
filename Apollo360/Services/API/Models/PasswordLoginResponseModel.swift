//
//  PasswordLoginResponseModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

struct PasswordLoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let user: UserInfo
    let message: String?

    struct UserInfo: Decodable {
        let a360Id: String?
        let patientId: String?
        let email: String
        let username: String
        let firstName: String
        let lastName: String

        private enum CodingKeys: String, CodingKey {
            case a360Id = "id"
            case patientId
            case email
            case username
            case firstName
            case lastName
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            func decodeString(_ key: CodingKeys) -> String? {
                if let stringValue = try? container.decode(String.self, forKey: key) {
                    return stringValue
                }
                if let intValue = try? container.decode(Int.self, forKey: key) {
                    return String(intValue)
                }
                return nil
            }

            a360Id = decodeString(.a360Id)
            patientId = decodeString(.patientId)
            email = (try? container.decode(String.self, forKey: .email)) ?? ""
            username = (try? container.decode(String.self, forKey: .username)) ?? ""
            firstName = (try? container.decode(String.self, forKey: .firstName)) ?? ""
            lastName = (try? container.decode(String.self, forKey: .lastName)) ?? ""
        }

        var fullName: String {
            let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(trimmedFirst) \(trimmedLast)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    var patientId: String? { user.patientId }
    var a360Id: String? { user.a360Id }
    var displayName: String {
        let name = user.fullName
        return name.isEmpty ? user.username : name
    }
}
