import Foundation
import Combine

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var pushNotifications = true
    @Published var textMessages = false
    @Published var emails = true
    @Published private(set) var isLoading = false
    @Published private(set) var alertTitle = "Notification Settings"
    @Published private(set) var alertMessage: String?

    private let session: SessionManager
    private let service: NotificationSettingsAPIService
    private var hasLoaded = false

    init(session: SessionManager) {
        self.session = session
        self.service = .shared
    }

    func loadSettings() {
        guard !hasLoaded else { return }
        guard let token = session.accessToken else {
            showError("You're not signed in.")
            return
        }
        hasLoaded = true
        isLoading = true
        service.fetchSettings(bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let settings):
                self.pushNotifications = settings.pushNotifications
                self.textMessages = settings.textMessages
                self.emails = settings.emails
            case .failure(let error):
                self.showError(Self.prettyMessage(for: error))
            }
        }
    }

    func updatePushNotifications(_ isOn: Bool) {
        let previous = pushNotifications
        pushNotifications = isOn
        updateSettings(rollback: { self.pushNotifications = previous })
    }

    func updateTextMessages(_ isOn: Bool) {
        let previous = textMessages
        textMessages = isOn
        updateSettings(rollback: { self.textMessages = previous })
    }

    func updateEmails(_ isOn: Bool) {
        let previous = emails
        emails = isOn
        updateSettings(rollback: { self.emails = previous })
    }

    func clearAlert() {
        alertMessage = nil
    }

    private func updateSettings(rollback: @escaping () -> Void) {
        guard let token = session.accessToken else {
            rollback()
            showError("You're not signed in.")
            return
        }

        let request = NotificationSettingsRequest(
            pushNotifications: pushNotifications,
            textMessages: textMessages,
            emails: emails
        )

        isLoading = true
        service.updateSettings(bearerToken: token, request: request) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let settings):
                self.pushNotifications = settings.pushNotifications
                self.textMessages = settings.textMessages
                self.emails = settings.emails
                self.alertTitle = "Success"
                self.alertMessage = "Notification settings updated successfully."
            case .failure(let error):
                rollback()
                self.showError(Self.prettyMessage(for: error))
            }
        }
    }

    private func showError(_ message: String) {
        alertTitle = "Error"
        alertMessage = message
    }

    private static func prettyMessage(for error: APIError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid URL."
        case .encodingFailed(let err), .decodingFailed(let err):
            return "Parsing failed: \(err.localizedDescription)"
        case .requestFailed(let err):
            return err.localizedDescription
        case .invalidResponse:
            return "Invalid server response."
        case .serverError(let code, _):
            return "Server error (\(code)). Please try again."
        case .noData:
            return "No data received."
        }
    }
}
