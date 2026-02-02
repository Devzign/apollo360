//
//  MessageEntry.swift
//  Apollo360
//
//  Created by Amit Sinha on 29/01/26.
//

import Foundation

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

    var id: Int { entryId }

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
}
