//
//  MessageProvider.swift
//  Apollo360
//
//  Created by Amit Sinha on 29/01/26.
//

import Foundation

struct MessageProvider: Decodable, Identifiable {
    let memberId: Int
    let patientId: Int
    let name: String
    let email: String
    let roleId: Int
    let avatarFilename: String
    let avatarURL: String

    var id: Int { memberId }

    enum CodingKeys: String, CodingKey {
        case memberId = "member_id"
        case patientId = "patient_id"
        case patientName = "patient_name"
        case avatarFilename = "avatar_filename"
        case email
        case roleId = "role_id"
        case avatarURL = "avatar_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try container.decode(Int.self, forKey: .memberId)
        patientId = try container.decodeIfPresent(Int.self, forKey: .patientId) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .patientName) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        roleId = try container.decodeIfPresent(Int.self, forKey: .roleId) ?? 0
        avatarFilename = try container.decodeIfPresent(String.self, forKey: .avatarFilename) ?? ""
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL) ?? ""
    }
}
