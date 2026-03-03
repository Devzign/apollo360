import Foundation

struct DeviceSyncConfiguration {
    let validicBaseURLV2: String
    let organizationID: String
    let validicToken: String
    let validicSessionUserID: String
    let validicSessionOrganizationID: String
    let validicSessionAccessToken: String

    // Inject Validic values from your secure configuration layer.
    // Current default reads optional Info.plist keys to keep secrets out of source.
    static func make(sessionUserID: String, sessionAccessToken: String?) -> DeviceSyncConfiguration {
        let info = Bundle.main.infoDictionary ?? [:]
        return DeviceSyncConfiguration(
            validicBaseURLV2: info["VALIDIC_URL_V2"] as? String ?? "",
            organizationID: info["VALIDIC_ORGANIZATION_ID"] as? String ?? "",
            validicToken: info["VALIDIC_TOKEN"] as? String ?? "",
            validicSessionUserID: sessionUserID,
            validicSessionOrganizationID: info["VALIDIC_ORGANIZATION_ID"] as? String ?? "",
            validicSessionAccessToken: sessionAccessToken ?? ""
        )
    }

    var isReadyForProfileFetch: Bool {
        !validicBaseURLV2.isEmpty && !organizationID.isEmpty && !validicToken.isEmpty
    }

    var isReadyForSession: Bool {
        !validicSessionUserID.isEmpty && !validicSessionOrganizationID.isEmpty && !validicSessionAccessToken.isEmpty
    }
}

struct StaticDeviceCatalogItem: Identifiable, Hashable {
    let id = UUID()
    let sourceType: String
    let displayName: String
}

struct ValidicUserProfile: Decodable {
    let uid: String?
    let marketplaceURL: String?
    let sources: [ValidicSource]

    private enum CodingKeys: String, CodingKey {
        case uid
        case marketplaceURL = "marketplace_url"
        case marketplaceUrl = "marketplaceUrl"
        case marketplace
        case sources
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        uid = try container.decodeIfPresent(String.self, forKey: .uid)
        sources = try container.decodeIfPresent([ValidicSource].self, forKey: .sources) ?? []
        marketplaceURL =
            try container.decodeIfPresent(String.self, forKey: .marketplaceURL) ??
            container.decodeIfPresent(String.self, forKey: .marketplaceUrl) ??
            container.decodeIfPresent(String.self, forKey: .marketplace)
    }
}

struct ValidicSource: Decodable, Hashable {
    let type: String
    let connectedAt: Date?
    let lastProcessedAt: Date?

    private enum CodingKeys: String, CodingKey {
        case type
        case connectedAt = "connected_at"
        case lastProcessedAt = "last_processed_at"
    }
}

struct SyncDeviceRow: Identifiable, Hashable {
    let id = UUID()
    let type: DeviceSourceType
    let sourceTypeRaw: String
    let title: String
    let isConnected: Bool
    let connectedAt: Date?
    let lastProcessedAt: Date?

    var subtitle: String {
        if isConnected {
            return "Connected"
        }
        return "Disconnected"
    }
}

enum DeviceSourceType: String, CaseIterable, Hashable {
    case appleHealth = "apple_health"
    case fitbit = "fitbit"
    case garmin = "garmin"
    case omron = "omron"
    case strava = "strava"
    case oura = "oura"
    case withings = "withings"
    case unknown = "unknown"

    init(rawType: String) {
        let normalized = rawType
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
        self = DeviceSourceType(rawValue: normalized) ?? .unknown
    }

    var displayName: String {
        switch self {
        case .appleHealth: return "Apple Health"
        case .fitbit: return "Fitbit"
        case .garmin: return "Garmin"
        case .omron: return "Omron"
        case .strava: return "Strava"
        case .oura: return "Oura"
        case .withings: return "Withings"
        case .unknown: return "Other Device"
        }
    }

    var iconName: String {
        switch self {
        case .appleHealth: return "heart.fill"
        case .fitbit: return "figure.walk"
        case .garmin: return "map.fill"
        case .omron: return "waveform.path.ecg"
        case .strava: return "figure.run"
        case .oura: return "moon.stars.fill"
        case .withings: return "scalemass.fill"
        case .unknown: return "sensor.tag.radiowaves.forward"
        }
    }

    static let displayMappingTable: [String: String] = [
        "apple_health": "Apple Health",
        "fitbit": "Fitbit",
        "garmin": "Garmin",
        "omron": "Omron",
        "strava": "Strava",
        "oura": "Oura",
        "withings": "Withings"
    ]
}

struct HealthKitSyncResult {
    let activitySummaryCount: Int
    let workoutCount: Int
}

enum DeviceSyncError: LocalizedError {
    case invalidConfiguration(String)
    case invalidURL
    case invalidResponse
    case cannotOpenMarketplace
    case healthKitNotAvailable

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let reason):
            return reason
        case .invalidURL:
            return "Unable to build the request URL."
        case .invalidResponse:
            return "The server returned an invalid response."
        case .cannotOpenMarketplace:
            return "Unable to open marketplace URL."
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device."
        }
    }
}

extension JSONDecoder {
    static var validicDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = ISO8601DateFormatter.full.date(from: string) {
                return date
            }
            if let date = ISO8601DateFormatter.fractional.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Invalid date: \(string)")
        }
        return decoder
    }
}

extension ISO8601DateFormatter {
    static let full: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
