import Foundation
import Combine

@MainActor
final class HealthSyncViewModel: ObservableObject {
  enum State {
    case idle
    case syncing
    case success(String)
    case failure(String)
  }

  @Published private(set) var state: State = .idle
  @Published private(set) var lastSyncedAt: Date?
  @Published private(set) var marketplaceURL: String?
  @Published private(set) var sourceCount: Int = 0
  @Published private(set) var sourceTypes: [String] = []
  @Published private(set) var validicUserID: String?
  @Published private(set) var validicUID: String?
  @Published private(set) var mobileToken: String?
  @Published private(set) var timezone: String?
  @Published private(set) var userStatus: String?

  private let service: ApolloSyncService
  private let userDefaults: UserDefaults
  private let lastSyncKey = "lastDeviceSyncAt"
  private let cachedUserKey = "Apollo360.validicUser"

  init(service: ApolloSyncService, userDefaults: UserDefaults = .standard) {
    self.service = service
    self.userDefaults = userDefaults
    self.lastSyncedAt = userDefaults.object(forKey: lastSyncKey) as? Date
    restoreCachedUser()
  }

  func sync(encodedUsername: String, deviceId: String) async {
    print("🚀 [DeviceSync] Sync tapped | deviceId=\(deviceId)")
    state = .syncing

    do {
      let user = try await service.runFullSync(
        encodedPatientUsername: encodedUsername,
        deviceId: deviceId
      )

      apply(user: user)

      let now = Date()
      self.lastSyncedAt = now
      self.userDefaults.set(now, forKey: lastSyncKey)

      state = .success("Sync complete. Connected sources: \(sourceCount)")
      print("🎉 [DeviceSync] Sync success | sources=\(sourceCount)")
    } catch {
      print("❌ [DeviceSync] Sync failed | error=\(error.localizedDescription)")
      state = .failure(error.localizedDescription)
    }
  }

  func refreshSources(uidToken: String? = nil) async {
    do {
      let resolvedUID = uidToken ?? validicUID
      guard let resolvedUID, !resolvedUID.isEmpty else {
        throw ApolloSyncError.api("Validic uid is not available. Run the initial sync first.")
      }

      let user = try await service.refreshValidicSources(uidToken: resolvedUID)
      try service.startSession(for: user)
      apply(user: user)
    } catch {
      state = .failure(error.localizedDescription)
    }
  }

  func syncFromCachedSession() async {
    do {
      guard let cachedUser = currentCachedUser else {
        throw ApolloSyncError.api("Validic user is not available yet. Run the initial sync first.")
      }

      try service.startSession(for: cachedUser)
      try await service.syncHistoricalHealthKitData(validicUser: cachedUser)

      let now = Date()
      self.lastSyncedAt = now
      self.userDefaults.set(now, forKey: lastSyncKey)
      state = .success("Sync complete. Connected sources: \(sourceCount)")
    } catch {
      state = .failure(error.localizedDescription)
    }
  }

  private var currentCachedUser: ValidicUserResponse? {
    guard let data = userDefaults.data(forKey: cachedUserKey) else { return nil }
    return try? JSONDecoder().decode(ValidicUserResponse.self, from: data)
  }

  private func restoreCachedUser() {
    guard let user = currentCachedUser else { return }
    apply(user: user, persist: false)
  }

  private func apply(user: ValidicUserResponse, persist: Bool = true) {
    self.validicUserID = user.id
    self.validicUID = user.uid
    self.mobileToken = user.mobile.token
    self.marketplaceURL = user.marketplace.url
    self.timezone = user.location?.timezone
    self.userStatus = user.status

    let sources = user.sources ?? []
    self.sourceCount = sources.count
    self.sourceTypes = sources.map { $0.type.lowercased() }

    if persist, let data = try? JSONEncoder().encode(user) {
      userDefaults.set(data, forKey: cachedUserKey)
    }
  }
}
