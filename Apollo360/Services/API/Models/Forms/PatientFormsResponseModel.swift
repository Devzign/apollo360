//
//  PatientFormsResponseModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 27/01/26.
//

import Foundation

struct PatientFormsAPIResponse: Decodable {
    let data: [PatientFormAPIModel]
}

struct PatientFormAPIModel: Decodable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let signed: Bool
    let signedDate: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case signed
        case signedDate = "signedDate"
        case signed_date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        signed = try container.decodeIfPresent(Bool.self, forKey: .signed) ?? false
        signedDate = try container.decodeIfPresent(String.self, forKey: .signedDate)
            ?? (try container.decodeIfPresent(String.self, forKey: .signed_date))
    }
}
