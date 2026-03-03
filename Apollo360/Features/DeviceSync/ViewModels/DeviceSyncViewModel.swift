import Foundation
import Combine
import SwiftUI
import UIKit

@MainActor
final class DeviceSyncViewModel: ObservableObject {
    @Published private(set) var devices: [SyncDeviceRow] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncAt: Date?
    @Published var alertMessage: String?

    private let session: SessionManager
    private let catalogService: DeviceCatalogServicing
    private let validicUserService: ValidicUserServicing
    private let healthSyncService: HealthKitSyncServicing
    private let defaults: UserDefaults

    private var marketplaceURL: URL?

    private enum Constants {
        static let lastSyncAtKey = "lastDeviceSyncAt"
    }

    init(session: SessionManager,
         catalogService: DeviceCatalogServicing,
         validicUserService: ValidicUserServicing,
         healthSyncService: HealthKitSyncServicing,
         defaults: UserDefaults = .standard) {
        self.session = session
        self.catalogService = catalogService
        self.validicUserService = validicUserService
        self.healthSyncService = healthSyncService
        self.defaults = defaults
        self.lastSyncAt = defaults.object(forKey: Constants.lastSyncAtKey) as? Date
    }

    convenience init(session: SessionManager) {
        self.init(
            session: session,
            catalogService: DeviceCatalogService(),
            validicUserService: ValidicUserService(),
            healthSyncService: HealthKitSyncService()
        )
    }

    var lastSyncText: String {
        guard let lastSyncAt else {
            return "Last Sync: Never"
        }
        return "Last Sync: \(Self.syncDateFormatter.string(from: lastSyncAt))"
    }

    func onAppear() {
        guard devices.isEmpty else { return }
        Task {
            await refreshDevices()
        }
    }

    func refreshDevices() async {
        guard let uid = resolvedUID() else {
            alertMessage = "Unable to resolve user ID for Validic profile."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let configuration = DeviceSyncConfiguration.make(
                sessionUserID: uid,
                sessionAccessToken: session.accessToken
            )

            async let catalog = catalogService.fetchStaticCatalog()
            async let profile = validicUserService.fetchUserProfile(configuration: configuration, uid: uid)

            let (catalogItems, profilePayload) = try await (catalog, profile)
            marketplaceURL = profilePayload.marketplaceURL.flatMap(URL.init(string:))
            devices = merge(catalog: catalogItems, sources: profilePayload.sources)
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func syncWithAppleHealth() async {
        guard !isSyncing else { return }
        guard let uid = resolvedUID() else {
            alertMessage = "Unable to resolve user ID for sync session."
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let configuration = DeviceSyncConfiguration.make(
                sessionUserID: uid,
                sessionAccessToken: session.accessToken
            )

            _ = try await healthSyncService.performThirtyDaySync(configuration: configuration)
            let now = Date()
            defaults.set(now, forKey: Constants.lastSyncAtKey)
            lastSyncAt = now

            await refreshDevices()
            alertMessage = "Apple Health sync completed successfully."
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    func openMarketplace() {
        guard let marketplaceURL else {
            alertMessage = "Marketplace URL is not available for this user."
            return
        }
        guard UIApplication.shared.canOpenURL(marketplaceURL) else {
            alertMessage = DeviceSyncError.cannotOpenMarketplace.localizedDescription
            return
        }
        UIApplication.shared.open(marketplaceURL)
    }

    private func resolvedUID() -> String? {
        // Inject your exact Validic user uid mapping here if it differs from session.patientId.
        if let patientId = session.patientId, !patientId.isEmpty {
            return patientId
        }
        if let a360Id = session.a360Id, !a360Id.isEmpty {
            return a360Id
        }
        return nil
    }

    private func merge(catalog: [StaticDeviceCatalogItem], sources: [ValidicSource]) -> [SyncDeviceRow] {
        let sourceByType: [String: ValidicSource] = Dictionary(
            uniqueKeysWithValues: sources.map {
                (
                    $0.type.lowercased().replacingOccurrences(of: " ", with: "_"),
                    $0
                )
            }
        )

        let catalogByType: [String: StaticDeviceCatalogItem] = Dictionary(
            uniqueKeysWithValues: catalog.map {
                (
                    $0.sourceType.lowercased().replacingOccurrences(of: " ", with: "_"),
                    $0
                )
            }
        )

        let allTypes = Set(catalogByType.keys).union(sourceByType.keys)

        return allTypes
            .map { rawType in
                let sourceType = DeviceSourceType(rawType: rawType)
                let source = sourceByType[rawType]
                let title = catalogByType[rawType]?.displayName ?? sourceType.displayName

                return SyncDeviceRow(
                    type: sourceType,
                    sourceTypeRaw: rawType,
                    title: title,
                    isConnected: source?.connectedAt != nil,
                    connectedAt: source?.connectedAt,
                    lastProcessedAt: source?.lastProcessedAt
                )
            }
            .sorted { $0.title < $1.title }
    }

    private static let syncDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
