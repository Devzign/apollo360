//
//  PasswordLoginViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation
import Combine
import UIKit

@MainActor
final class PasswordLoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    @Published var isLoading: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var showAlert: Bool = false
    @Published var alertStyle: AlertStyle = .standard
    @Published var faceIdEnabled: Bool = false
    @Published private(set) var canUseBiometrics: Bool = false
    var onLoginSuccess: ((PasswordLoginResponse) -> Void)?

    init() {
        canUseBiometrics = FaceIDPreferenceStore.canUseBiometrics()
    }

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
                self.syncFaceIDPreference(using: response) { warning in
                    self.onLoginSuccess?(response)
                    let base = "Logged in as \(response.user.username)."
                    if let warning, !warning.isEmpty {
                        self.showAlert(title: "Welcome \(response.user.firstName)", message: "\(base)\n\n\(warning)")
                    } else {
                        self.showAlert(title: "Welcome \(response.user.firstName)", message: base)
                    }
                }
            case .failure(let error):
                self.showAlert(title: "Login failed", message: error.localizedDescription, style: .error)
            }
        }
    }

    func configureFaceIDSelection(for patientId: String?) {
        canUseBiometrics = FaceIDPreferenceStore.canUseBiometrics()
        faceIdEnabled = FaceIDPreferenceStore.isEnabled(for: patientId)
    }

    private func showAlert(title: String, message: String, style: AlertStyle = .standard) {
        alertTitle = title
        alertMessage = message
        alertStyle = style
        showAlert = true
    }

    private func syncFaceIDPreference(using response: PasswordLoginResponse,
                                      completion: @escaping (String?) -> Void) {
        guard let patientId = response.patientId, !patientId.isEmpty else {
            completion(nil)
            return
        }

        let payload = PatientFaceIDRequest(patientId: patientId, faceIdEnabled: faceIdEnabled)
        APIClient.shared.updatePatientFaceID(with: payload) { result in
            switch result {
            case .success:
                FaceIDPreferenceStore.setPreference(enabled: self.faceIdEnabled, patientId: patientId)
                completion(nil)
            case .failure(let error):
                completion("Logged in, but Face ID preference was not updated. \(error.localizedDescription)")
            }
        }
    }

}
