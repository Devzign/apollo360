import Foundation
import Combine

@MainActor
final class PasswordLoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    @Published var isLoading: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    var onLoginSuccess: ((PasswordLoginResponse) -> Void)?

    var isFormValid: Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func login() {
        guard isFormValid else {
            showAlert(title: "Incomplete form", message: "Username and password are required.")
            return
        }

        let request = PasswordLoginRequest(
            username: username.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            rememberMe: rememberMe
        )

        isLoading = true
        APIClient.shared.loginWithPassword(with: request) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.onLoginSuccess?(response)
                self.showAlert(title: "Welcome \(response.user.firstName)", message: "Logged in as \(response.user.username).")
            case .failure(let error):
                self.showAlert(title: "Login failed", message: error.localizedDescription)
            }
        }
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
