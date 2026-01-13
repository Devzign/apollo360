//
//  VerifyOTPRequestModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

struct VerifyOTPRequest: Encodable {
    let phone: String
    let otp: String
    let deviceId: String
    let rememberDevice: Bool
}
