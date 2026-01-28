//
//  PatientLoginResponseModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

struct PatientLoginResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let message: String?
    /// Patient identifier returned by the API (string or int on the wire).
    let patientId: String?
    private let decodedA360Id: String?
    let user: UserInfo?

    struct UserInfo: Decodable {
        let a360Id: String?
        let patientId: String?
        let email: String
        let username: String
        let firstName: String
        let lastName: String
        let role: String?

        private enum CodingKeys: String, CodingKey {
            case a360Id = "id"
            case patientId
            case email
            case username
            case firstName
            case lastName
            case role
            case userId // legacy fallback
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

            a360Id = decodeString(.a360Id) ?? decodeString(.userId)
            patientId = decodeString(.patientId)
            email = (try? container.decode(String.self, forKey: .email)) ?? ""
            username = (try? container.decode(String.self, forKey: .username)) ?? ""
            firstName = (try? container.decode(String.self, forKey: .firstName)) ?? ""
            lastName = (try? container.decode(String.self, forKey: .lastName)) ?? ""
            role = try? container.decode(String.self, forKey: .role)
        }

        var fullName: String {
            let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
            return "\(trimmedFirst) \(trimmedLast)".trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
        case expiresIn
        case message
        case patientId
        case user
        case userId // legacy fallback
        case id     // legacy fallback
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

        accessToken = try container.decodeIfPresent(String.self, forKey: .accessToken)
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        user = try container.decodeIfPresent(UserInfo.self, forKey: .user)
        decodedA360Id = decodeString(.id) ?? decodeString(.userId)
        patientId = decodeString(.patientId) ?? decodeString(.userId) ?? decodeString(.id)
    }

    var patientIdentifier: String? {
        if let patientId, !patientId.isEmpty {
            return patientId
        }
        if let userPatientId = user?.patientId, !userPatientId.isEmpty {
            return userPatientId
        }
        return nil
    }

    var a360Id: String? {
        decodedA360Id ?? user?.a360Id
    }

    var displayName: String? {
        guard let user = user else { return nil }
        let name = user.fullName
        return name.isEmpty ? nil : name
    }
}
