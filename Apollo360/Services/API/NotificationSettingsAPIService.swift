import Foundation

final class NotificationSettingsAPIService {
    static let shared = NotificationSettingsAPIService()
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchSettings(
        bearerToken: String,
        completion: @escaping (Result<NotificationSettingsResponse, APIError>) -> Void
    ) {
        client.request(
            endpoint: APIEndpoint.notificationSettings,
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"],
            responseType: NotificationSettingsResponse.self,
            completion: completion
        )
    }

    func updateSettings(
        bearerToken: String,
        request: NotificationSettingsRequest,
        completion: @escaping (Result<NotificationSettingsResponse, APIError>) -> Void
    ) {
        client.request(
            endpoint: APIEndpoint.notificationSettings,
            method: .patch,
            body: request,
            headers: ["Authorization": "Bearer \(bearerToken)"],
            responseType: NotificationSettingsResponse.self,
            completion: completion
        )
    }
}
