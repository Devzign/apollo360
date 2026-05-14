//
//  SessionManager.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation
import Combine
import LocalAuthentication

extension Notification.Name {
    static let sessionInvalidated = Notification.Name("sessionInvalidated")
    static let sessionTokensRefreshed = Notification.Name("sessionTokensRefreshed")
}

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var requiresBiometricUnlock: Bool = false
    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var patientId: String?
    @Published private(set) var a360Id: String?
    @Published private(set) var username: String?
    @Published private(set) var role: String?
    @Published private(set) var careGiverKey: String?
    @Published private(set) var permissions: [String] = []
    
    private enum StorageKeys {
        static let accessToken = "Apollo360.accessToken"
        static let refreshToken = "Apollo360.refreshToken"
        static let patientId = "Apollo360.patientId"
        static let a360Id = "Apollo360.a360Id"
        static let username = "Apollo360.username"
        static let role = "Apollo360.role"
        static let careGiverKey = "Apollo360.careGiverKey"
        static let permissions = "Apollo360.permissions"
    }
    
    private let defaults = UserDefaults.standard
    
    init() {
        loadFromStorage()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSessionInvalidation),
                                               name: .sessionInvalidated,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSessionTokensRefreshed(_:)),
                                               name: .sessionTokensRefreshed,
                                               object: nil)
    }
    
    func updateSession(accessToken: String?,
                       refreshToken: String?,
                       patientId: String?,
                       a360Id: String?,
                       username: String?,
                       role: String? = nil,
                       careGiverKey: String? = nil,
                       permissions: [String] = []) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.patientId = patientId
        self.a360Id = a360Id
        self.username = username
        self.role = role
        self.careGiverKey = careGiverKey
        self.permissions = permissions
        self.requiresBiometricUnlock = false
        self.isAuthenticated = accessToken != nil && patientId != nil
        persist()
    }

    func unlockWithBiometrics(completion: @escaping (Result<Void, Error>) -> Void) {
        guard requiresBiometricUnlock, accessToken != nil, patientId != nil else {
            completion(.failure(BiometricAuthError.noLockedSession))
            return
        }

        BiometricAuthenticator.authenticate(reason: "Use Face ID to sign in to Apollo360.") { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                self.requiresBiometricUnlock = false
                self.isAuthenticated = true
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func clearSession() {
        DispatchQueue.main.async {
            self.accessToken = nil
            self.refreshToken = nil
            self.patientId = nil
            self.a360Id = nil
            self.username = nil
            self.role = nil
            self.careGiverKey = nil
            self.permissions = []
            self.requiresBiometricUnlock = false
            self.isAuthenticated = false
            
            self.defaults.removeObject(forKey: StorageKeys.accessToken)
            self.defaults.removeObject(forKey: StorageKeys.refreshToken)
            self.defaults.removeObject(forKey: StorageKeys.patientId)
            self.defaults.removeObject(forKey: StorageKeys.a360Id)
            self.defaults.removeObject(forKey: StorageKeys.username)
            self.defaults.removeObject(forKey: StorageKeys.role)
            self.defaults.removeObject(forKey: StorageKeys.careGiverKey)
            self.defaults.removeObject(forKey: StorageKeys.permissions)
        }
    }
    
    private func loadFromStorage() {
        accessToken = defaults.string(forKey: StorageKeys.accessToken)
        refreshToken = defaults.string(forKey: StorageKeys.refreshToken)
        patientId = defaults.string(forKey: StorageKeys.patientId)
        a360Id = defaults.string(forKey: StorageKeys.a360Id)
        username = defaults.string(forKey: StorageKeys.username)
        role = defaults.string(forKey: StorageKeys.role)
        careGiverKey = defaults.string(forKey: StorageKeys.careGiverKey)
        permissions = defaults.stringArray(forKey: StorageKeys.permissions) ?? []
        let hasSession = accessToken != nil && patientId != nil
        requiresBiometricUnlock = hasSession && FaceIDPreferenceStore.isEnabled(for: patientId)
        isAuthenticated = hasSession && !requiresBiometricUnlock
    }
    
    private func persist() {
        defaults.set(accessToken, forKey: StorageKeys.accessToken)
        defaults.set(refreshToken, forKey: StorageKeys.refreshToken)
        defaults.set(patientId, forKey: StorageKeys.patientId)
        defaults.set(a360Id, forKey: StorageKeys.a360Id)
        defaults.set(username, forKey: StorageKeys.username)
        defaults.set(role, forKey: StorageKeys.role)
        defaults.set(careGiverKey, forKey: StorageKeys.careGiverKey)
        defaults.set(permissions, forKey: StorageKeys.permissions)
    }
    
    @objc private func handleSessionInvalidation() {
        clearSession()
    }

    @objc private func handleSessionTokensRefreshed(_ notification: Notification) {
            guard let userInfo = notification.userInfo else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let token = userInfo["accessToken"] as? String, !token.isEmpty {
                    self.accessToken = token
                }
                if let token = userInfo["refreshToken"] as? String, !token.isEmpty {
                    self.refreshToken = token
                }
                self.persist()
            }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

enum FaceIDPreferenceStore {
    private enum StorageKeys {
        static let enabledPatientId = "Apollo360.faceID.patientId"
        static let faceIDEnabled = "Apollo360.faceID.enabled"
    }

    private static let defaults = UserDefaults.standard

    static func setPreference(enabled: Bool, patientId: String) {
        defaults.set(patientId, forKey: StorageKeys.enabledPatientId)
        defaults.set(enabled, forKey: StorageKeys.faceIDEnabled)
    }

    static func isEnabled(for patientId: String?) -> Bool {
        guard let patientId,
              let storedPatientId = defaults.string(forKey: StorageKeys.enabledPatientId),
              storedPatientId == patientId else {
            return false
        }
        return defaults.bool(forKey: StorageKeys.faceIDEnabled)
    }

    static func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
}

enum BiometricAuthenticator {
    static func authenticate(reason: String,
                             completion: @escaping (Result<Void, Error>) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(.failure(error ?? BiometricAuthError.unavailable))
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(authError ?? BiometricAuthError.failed))
                }
            }
        }
    }
}

enum BiometricAuthError: LocalizedError {
    case unavailable
    case failed
    case noLockedSession

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Face ID is not available on this device."
        case .failed:
            return "Face ID authentication failed."
        case .noLockedSession:
            return "No Face ID login session is available."
        }
    }
}
