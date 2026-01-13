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
    let userId: String?
    let user: UserInfo?

    struct UserInfo: Decodable {
        let id: Int
        let email: String
        let username: String
        let firstName: String
        let lastName: String
        let role: String?
    }

    var patientIdentifier: String? {
        if let userId, !userId.isEmpty {
            return userId
        }
        if let user = user {
            return "\(user.id)"
        }
        return nil
    }

    var displayName: String? {
        guard let user = user else { return nil }
        return "\(user.firstName) \(user.lastName)"
    }
}
