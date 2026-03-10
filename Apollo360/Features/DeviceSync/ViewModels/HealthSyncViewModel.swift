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

  private let service: ApolloSyncService
  private let userDefaults: UserDefaults
  private let lastSyncKey = "lastDeviceSyncAt"

  init(service: ApolloSyncService, userDefaults: UserDefaults = .standard) {
    self.service = service
    self.userDefaults = userDefaults
    self.lastSyncedAt = userDefaults.object(forKey: lastSyncKey) as? Date
  }

  func sync(encodedUsername: String, deviceId: String) async {
    print("🚀 [DeviceSync] Sync tapped | deviceId=\(deviceId)")
    state = .syncing

    do {
      let user = try await service.runFullSync(
        encodedPatientUsername: encodedUsername,
        deviceId: deviceId
      )

      self.marketplaceURL = user.marketplace.url
      let sources = user.sources ?? []
      self.sourceCount = sources.count
      self.sourceTypes = sources.map { $0.type.lowercased() }

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

  func refreshSources(uidToken: String) async {
    do {
      let user = try await service.refreshValidicSources(uidToken: uidToken)
      self.marketplaceURL = user.marketplace.url
      let sources = user.sources ?? []
      self.sourceCount = sources.count
      self.sourceTypes = sources.map { $0.type.lowercased() }
    } catch {
      state = .failure(error.localizedDescription)
    }
  }
}
