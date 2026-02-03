//
//  Profile.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation

struct Profile: Decodable {
    let id: Int
    let email: String
    let username: String
    let firstName: String
    let lastName: String
    let dateOfBirth: String?
    let phone: String?
    let avatarUrl: String?

    var fullName: String {
        [firstName, lastName]
            .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .joined(separator: " ")
    }

    var displayName: String {
        fullName.isEmpty ? username : fullName
    }
}
