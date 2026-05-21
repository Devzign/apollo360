//
//  MessageEntry.swift
//  Apollo360
//
//  Created by Amit Sinha on 29/01/26.
//

import Foundation
import Combine

struct MessageEntry: Decodable, Identifiable {
    let entryId: Int
    let messageType: Int
    let name: String
    let timestamp: Date?
    let message: String
    let urgent: String
    let topicId: Int?
    let topicTitle: String?
    let isUnread: Bool?
    let filePath: String?

    var id: String {
        if entryId != 0 {
            return String(entryId)
        }
        return "\(timestamp?.timeIntervalSince1970 ?? 0)-\(messageType)-\(name.hashValue)"
    }

    enum CodingKeys: String, CodingKey {
        case entryId = "entry_id"
        case messageType = "message_type"
        case name
        case timestamp
        case message
        case urgent
        case topicId = "topic_id"
        case topicTitle = "topic_title"
        case isUnread = "is_unread"
        case filePath = "file_path"
    }

    init(entryId: Int,
         messageType: Int,
         name: String,
         timestamp: Date?,
         message: String,
         urgent: String,
         topicId: Int?,
         topicTitle: String?,
         isUnread: Bool?,
         filePath: String?) {
        self.entryId = entryId
        self.messageType = messageType
        self.name = name
        self.timestamp = timestamp
        self.message = message
        self.urgent = urgent
        self.topicId = topicId
        self.topicTitle = topicTitle
        self.isUnread = isUnread
        self.filePath = filePath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entryId = try container.decodeIfPresent(Int.self, forKey: .entryId) ?? 0
        messageType = try container.decodeIfPresent(Int.self, forKey: .messageType) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        urgent = try container.decodeIfPresent(String.self, forKey: .urgent) ?? "0"
        topicId = try container.decodeIfPresent(Int.self, forKey: .topicId)
        topicTitle = try container.decodeIfPresent(String.self, forKey: .topicTitle)
        isUnread = try container.decodeIfPresent(Bool.self, forKey: .isUnread)
        filePath = try container.decodeIfPresent(String.self, forKey: .filePath)

        if let timestampString = try container.decodeIfPresent(String.self, forKey: .timestamp) {
            timestamp = MessageAPIDateParser.date(from: timestampString)
        } else {
            timestamp = nil
        }
    }
}

private enum MessageAPIDateParser {
    static let iso8601WithMillis: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let noTimezoneMillis: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static func date(from value: String) -> Date? {
        if let parsed = iso8601WithMillis.date(from: value) {
            return parsed
        }
        if let parsed = iso8601.date(from: value) {
            return parsed
        }
        return noTimezoneMillis.date(from: value)
    }
}
