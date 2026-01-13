import Foundation
import Combine

extension Notification.Name {
    static let sessionInvalidated = Notification.Name("sessionInvalidated")
}

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var patientId: String?
    @Published private(set) var username: String?
    
    private enum StorageKeys {
        static let accessToken = "Apollo360.accessToken"
        static let refreshToken = "Apollo360.refreshToken"
        static let patientId = "Apollo360.patientId"
        static let username = "Apollo360.username"
    }
    
    private let defaults = UserDefaults.standard
    
    init() {
        loadFromStorage()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleSessionInvalidation),
                                               name: .sessionInvalidated,
                                               object: nil)
    }
    
    func updateSession(accessToken: String?,
                       refreshToken: String?,
                       patientId: String?,
                       username: String?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.patientId = patientId
        self.username = username
        self.isAuthenticated = accessToken != nil && patientId != nil
        persist()
    }
    
    func clearSession() {
        DispatchQueue.main.async {
            self.accessToken = nil
            self.refreshToken = nil
            self.patientId = nil
            self.username = nil
            self.isAuthenticated = false
            
            self.defaults.removeObject(forKey: StorageKeys.accessToken)
            self.defaults.removeObject(forKey: StorageKeys.refreshToken)
            self.defaults.removeObject(forKey: StorageKeys.patientId)
            self.defaults.removeObject(forKey: StorageKeys.username)
        }
    }
    
    private func loadFromStorage() {
        accessToken = defaults.string(forKey: StorageKeys.accessToken)
        refreshToken = defaults.string(forKey: StorageKeys.refreshToken)
        patientId = defaults.string(forKey: StorageKeys.patientId)
        username = defaults.string(forKey: StorageKeys.username)
        isAuthenticated = accessToken != nil && patientId != nil
    }
    
    private func persist() {
        defaults.set(accessToken, forKey: StorageKeys.accessToken)
        defaults.set(refreshToken, forKey: StorageKeys.refreshToken)
        defaults.set(patientId, forKey: StorageKeys.patientId)
        defaults.set(username, forKey: StorageKeys.username)
    }
    
    @objc private func handleSessionInvalidation() {
        clearSession()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

