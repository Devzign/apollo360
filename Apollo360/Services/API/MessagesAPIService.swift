//
//  MessagesAPIService.swift
//  Apollo360
//
//  Created by Amit Sinha on 11/01/26.
//

import Foundation

final class MessagesAPIService {
    static let shared = MessagesAPIService()

    private init() {}

    func fetchConversation(patientId: Int,
                           a360hId: Int,
                           bearerToken: String,
                           completion: @escaping (Result<[MessageAPIModel], APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.messagesConversation(for: patientId, a360hId: a360hId),
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: MessagesAPIResponse.self) { result in
            switch result {
            case .success(let response):
                if response.success {
                    completion(.success(response.threads))
                } else {
                    completion(.failure(.serverError(statusCode: 500, data: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private struct MessagesAPIResponse: Decodable {
    let success: Bool
    let message: String?
    let threads: [MessageAPIModel]

    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case data
        case threads
        case conversation
        case conversations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decodeIfPresent(Bool.self, forKey: .success) ?? true
        message = try container.decodeIfPresent(String.self, forKey: .message)

        if let decodedThreads = try? container.decode([MessageAPIModel].self, forKey: .data) {
            threads = decodedThreads
        } else if let decodedThreads = try? container.decode([MessageAPIModel].self, forKey: .threads) {
            threads = decodedThreads
        } else if
            let decodedThreads = try? container.decode(MessagesData.self, forKey: .data),
            let unpacked = decodedThreads.data {
            threads = unpacked
        } else if let decodedThreads = try? container.decode([MessageAPIModel].self, forKey: .conversation) {
            threads = decodedThreads
        } else if let decodedThreads = try? container.decode([MessageAPIModel].self, forKey: .conversations) {
            threads = decodedThreads
        } else {
            threads = []
        }
    }
}

private struct MessagesData: Decodable {
    let messages: [MessageAPIModel]?
    let threads: [MessageAPIModel]?
    let conversation: [MessageAPIModel]?
    let conversations: [MessageAPIModel]?

    var data: [MessageAPIModel]? {
        messages ?? threads ?? conversation ?? conversations
    }
}

struct MessageAPIModel: Decodable {
    let id: String
    let senderName: String?
    let detail: String?
    let unreadCount: Int?
    let avatarURL: URL?
    let timestamp: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case threadId = "thread_id"
        case senderName
        case sender_full_name
        case name
        case detail
        case message
        case text
        case body
        case description
        case unreadCount = "unread_count"
        case unread
        case avatarURL = "avatar_url"
        case avatar
        case photo
        case timestamp
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decodeIfPresent(String.self, forKey: .threadId)
            ?? UUID().uuidString

        detail = Self.decodeString(from: container,
                                   keys: [.detail, .message, .text, .body, .description])

        senderName = Self.decodeString(from: container,
                                       keys: [.senderName, .sender_full_name, .name])

        unreadCount = Self.decodeInt(from: container,
                                     keys: [.unreadCount, .unread])

        if let avatarString = Self.decodeString(from: container,
                                                keys: [.avatarURL, .avatar, .photo]) {
            avatarURL = URL(string: avatarString)
        } else {
            avatarURL = nil
        }

        let createdAt = (try? container.decode(String.self, forKey: .createdAt))
            ?? (try? container.decode(String.self, forKey: .updatedAt))
            ?? (try? container.decode(String.self, forKey: .timestamp))

        if let createdValue = createdAt {
            timestamp = MessageDateFormatter.iso8601.date(from: createdValue)
        } else {
            timestamp = nil
        }
    }

    private static func decodeString(from container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> String? {
        for key in keys {
            guard let value = try? container.decode(String.self, forKey: key) else {
                continue
            }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return trimmed
            }
        }
        return nil
    }

    private static func decodeInt(from container: KeyedDecodingContainer<CodingKeys>, keys: [CodingKeys]) -> Int? {
        for key in keys {
            if let value = try? container.decode(Int.self, forKey: key) {
                return value
            }
        }
        return nil
    }
}

private enum MessageDateFormatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
