//
//  PatientLoginRequestModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

struct PatientLoginRequest: Encodable {
    let phone: String
    let dateOfBirth: String
    let deviceId: String
    let trustToken: String
}
