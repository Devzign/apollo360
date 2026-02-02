//
//  AppointmentsResponseModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 27/01/26.
//

import Foundation

struct AppointmentsAPIResponse: Decodable {
    let appointments: [AppointmentAPIModel]
    let acsId: String?
    let acsToken: String?

    private enum CodingKeys: String, CodingKey {
        case appointments
        case acsId = "acs_id"
        case acsToken = "acs_token"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appointments = try container.decodeIfPresent([AppointmentAPIModel].self, forKey: .appointments) ?? []
        acsId = try container.decodeIfPresent(String.self, forKey: .acsId)
        acsToken = try container.decodeIfPresent(String.self, forKey: .acsToken)
    }
}

struct AppointmentAPIModel: Decodable {
    let date: Date?
    let displayTime: String?
    let service: String?
    let provider: String
    let role: String?
    let isTelevisit: Bool
    let isManualEncounter: Bool
    let callType: String?
    let acsRoomId: String?

    private enum CodingKeys: String, CodingKey {
        case date
        case displayTime = "display_time"
        case service
        case provider
        case role
        case televisit
        case manualEncounter = "manual_encounter"
        case callType
        case acsRoomId = "acs_room_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let dateString = try container.decodeIfPresent(String.self, forKey: .date) {
            date = AppointmentAPIDateFormatter.iso8601.date(from: dateString)
        } else {
            date = nil
        }

        displayTime = try container.decodeIfPresent(String.self, forKey: .displayTime)
        service = try container.decodeIfPresent(String.self, forKey: .service)
        provider = try container.decodeIfPresent(String.self, forKey: .provider) ?? "Care Team"
        role = try container.decodeIfPresent(String.self, forKey: .role)

        let televisitValue = try container.decodeIfPresent(Int.self, forKey: .televisit)
        isTelevisit = (televisitValue ?? 0) == 1

        let manualValue = try container.decodeIfPresent(Int.self, forKey: .manualEncounter)
        isManualEncounter = (manualValue ?? 0) == 1

        callType = try container.decodeIfPresent(String.self, forKey: .callType)
        acsRoomId = try container.decodeIfPresent(String.self, forKey: .acsRoomId)
    }
}

private enum AppointmentAPIDateFormatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
