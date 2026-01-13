//
//  PasswordLoginRequestModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

struct PasswordLoginRequest: Encodable {
    let username: String
    let password: String
    let rememberMe: Bool
}
