//
//  CaregiverAuthModels.swift
//  Apollo360
//

import Foundation

struct CaregiverEmailRequest: Encodable {
    let email: String
}

struct CaregiverVerifyEmailRequest: Encodable {
    let token: String
    let email: String
}

struct CaregiverVerifyEmailResponse: Decodable {
    let success: Bool?
    let message: String?
}

struct CaregiverLoginRequest: Encodable {
    let phone: String
    let token: String
}

struct CaregiverLoginResponse: Decodable {
    let success: Bool?
    let message: String?
    let requiresOtp: Bool?
}

struct CaregiverPatientsResponse: Decodable {
    let patients: [CaregiverPatient]

    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        if let array = try? single.decode([CaregiverPatient].self) {
            patients = array
            return
        }
        if let wrapped = try? single.decode([String: [CaregiverPatient]].self),
           let data = wrapped["data"] {
            patients = data
            return
        }
        patients = []
    }
}

struct CaregiverPatient: Decodable, Identifiable {
    let patientId: String
    let patientName: String?
    let username: String?
    let dateOfBirth: String?
    let textStatus: Int?
    let emailStatus: Int?

    var id: String { patientId }

    enum CodingKeys: String, CodingKey {
        case patientId
        case patientName
        case username
        case dateOfBirth
        case textStatus
        case emailStatus
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let raw = try? c.decode(String.self, forKey: .patientId) {
            patientId = raw
        } else if let rawInt = try? c.decode(Int.self, forKey: .patientId) {
            patientId = String(rawInt)
        } else {
            patientId = ""
        }
        patientName = try? c.decode(String.self, forKey: .patientName)
        username = try? c.decode(String.self, forKey: .username)
        dateOfBirth = try? c.decode(String.self, forKey: .dateOfBirth)
        textStatus = try? c.decode(Int.self, forKey: .textStatus)
        emailStatus = try? c.decode(Int.self, forKey: .emailStatus)
    }
}

struct CaregiverSwitchPatientRequest: Encodable {
    let careGiverKey: String
    let currentToken: String
    let patientId: String
}

struct CaregiverSwitchPatientResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let user: PatientLoginResponse.UserInfo?
}

struct CaregiverNotificationRequest: Encodable {
    let patientId: Int
    let careGiverKey: String
    let column: String
    let value: Int
}

struct CaregiverNotificationResponse: Decodable {
    let success: Bool?
    let message: String?
}

struct AdminPatientLoginRequest: Encodable {
    let patientId: Int
    let dateOfBirth: String
}
