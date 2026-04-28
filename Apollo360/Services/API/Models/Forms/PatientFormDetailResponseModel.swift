//
//  PatientFormDetailResponseModel.swift
//  Apollo360
//

import Foundation

struct PatientFormDetailAPIResponse: Decodable {
    let data: PatientFormGroupAPIModel
}

struct PatientFormGroupAPIModel: Decodable {
    let requestedFormId: Int
    let forms: [PatientSubFormAPIModel]
    let groupFullySigned: Bool
}

struct PatientSubFormAPIModel: Decodable, Identifiable {
    struct Initials: Decodable {
        let initial1: Bool
        let initial2: Bool
    }

    let id: Int
    let title: String
    let body: String
    let signed: Bool
    let signedDate: String?
    let fullName: String?
    let initials: Initials
    let signatureRequired: Bool
}

struct PatientFormSignResponse: Decodable {
    let success: Bool
    let message: String
}
