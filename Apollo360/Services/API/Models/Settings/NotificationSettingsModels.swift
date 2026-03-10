import Foundation

struct NotificationSettingsResponse: Codable {
    let pushNotifications: Bool
    let textMessages: Bool
    let emails: Bool

    enum CodingKeys: String, CodingKey {
        case pushNotifications = "push_notifications"
        case textMessages = "text_messages"
        case emails
    }
}

struct NotificationSettingsRequest: Encodable {
    let pushNotifications: Bool
    let textMessages: Bool
    let emails: Bool

    enum CodingKeys: String, CodingKey {
        case pushNotifications = "push_notifications"
        case textMessages = "text_messages"
        case emails
    }
}
