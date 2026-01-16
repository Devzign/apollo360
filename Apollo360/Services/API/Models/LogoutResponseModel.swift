//
//  LogoutResponseModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

struct LogoutResponse: Decodable {
    let success: Bool?
    let message: String?
}
