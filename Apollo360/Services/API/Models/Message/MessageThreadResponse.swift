//
//  MessageThreadResponse.swift
//  Apollo360
//
//  Created by Amit Sinha on 29/01/26.
//

import Foundation

struct MessageThreadResponse: Decodable {
    let patientId: Int
    let a360hId: Int
    let patientName: String
    let dob: String?
    let messages: [MessageEntry]

    enum CodingKeys: String, CodingKey {
        case patientId = "patient_id"
        case a360hId = "a360h_id"
        case patientName = "patient_name"
        case dob
        case messages
    }
}
