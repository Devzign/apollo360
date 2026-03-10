import Foundation
import UIKit

#if canImport(ValidicCore) && canImport(ValidicHealthKit)
import ValidicCore
import ValidicHealthKit
import HealthKit
#endif

struct ApolloSyncConfig {
  let ppBaseURL: URL
  let validicBaseURL: URL
  let organizationId: String
  let validicToken: String

  static func fromInfoPlist() throws -> ApolloSyncConfig {
    let bundle = Bundle.main

    guard
      let ppBase = bundle.object(forInfoDictionaryKey: "PP_BASE_URL") as? String,
      let validicBase = bundle.object(forInfoDictionaryKey: "VALIDIC_URL_V2") as? String,
      let orgId = bundle.object(forInfoDictionaryKey: "ORGANISATION_ID") as? String,
      let token = bundle.object(forInfoDictionaryKey: "VALIDIC_TOKEN") as? String,
      let ppURL = URL(string: ppBase),
      let validicURL = URL(string: validicBase)
    else {
      throw ApolloSyncError.configuration("Missing one or more required Info.plist values: PP_BASE_URL, VALIDIC_URL_V2, ORGANISATION_ID, VALIDIC_TOKEN")
    }

    return ApolloSyncConfig(
      ppBaseURL: ppURL,
      validicBaseURL: validicURL,
      organizationId: orgId,
      validicToken: token
    )
  }
}

enum ApolloSyncError: LocalizedError {
  case configuration(String)
  case api(String)
  case platform(String)

  var errorDescription: String? {
    switch self {
    case .configuration(let message), .api(let message), .platform(let message):
      return message
    }
  }
}

struct UsernameCheckResponse: Decodable {
  let return_code: String
  let patient_id: String?
  let patient_key: String?
  let message: String?
}

struct HandshakeResponse: Decodable {
  let success: Bool
  let message: String
  let token: String
}

struct ValidicUserResponse: Decodable {
  struct Mobile: Decodable {
    let token: String
  }

  struct Marketplace: Decodable {
    let token: String?
    let url: String
  }

  struct Source: Decodable {
    let type: String
    let connected_at: String
    let last_processed_at: String
  }

  let id: String
  let uid: String
  let marketplace: Marketplace
  let mobile: Mobile
  let sources: [Source]?
}

final class ApolloSyncService {
  private let config: ApolloSyncConfig
  private let session: URLSession

  init(config: ApolloSyncConfig, session: URLSession = .shared) {
    self.config = config
    self.session = session
  }

  func runFullSync(encodedPatientUsername: String, deviceId: String) async throws -> ValidicUserResponse {
    print("📲 [DeviceSync] runFullSync started | deviceId=\(deviceId)")
    let usernameCheck = try await fetchUsernameCheck(encodedPatientUsername: encodedPatientUsername)
    print("✅ [DeviceSync] usernameCheck return_code=\(usernameCheck.return_code)")

    guard usernameCheck.return_code == "400" else {
      throw ApolloSyncError.api("usernameCheck returned code \(usernameCheck.return_code). Expected 400 for handshake flow.")
    }

    guard let patientIdRaw = usernameCheck.patient_id, let patientKeyRaw = usernameCheck.patient_key else {
      throw ApolloSyncError.api("usernameCheck did not return patient_id or patient_key.")
    }

    let patientId = base64(patientIdRaw)
    let patientKey = base64(patientKeyRaw)

    let handshake = try await performHandshake(
      patientId: patientId,
      patientKey: patientKey,
      deviceId: deviceId
    )
    print("✅ [DeviceSync] handshake success=\(handshake.success)")

    guard handshake.success else {
      throw ApolloSyncError.api(handshake.message)
    }

    let validicUser = try await createOrFetchValidicUser(uidToken: handshake.token)
    print("✅ [DeviceSync] validic user id=\(validicUser.id) uid=\(validicUser.uid)")

    try startValidicSession(
      validicUserID: validicUser.id,
      accessToken: validicUser.mobile.token
    )
    print("✅ [DeviceSync] Validic session started")

    try await configureHealthKitAndFetchHistory()
    print("✅ [DeviceSync] HealthKit subscriptions/history done")

    return validicUser
  }

  func refreshValidicSources(uidToken: String) async throws -> ValidicUserResponse {
    var components = URLComponents(url: config.validicBaseURL, resolvingAgainstBaseURL: false)!
    components.path = "/organizations/\(config.organizationId)/users/\(uidToken)"
    components.queryItems = [URLQueryItem(name: "token", value: config.validicToken)]
    return try await get(url: try requiredURL(from: components))
  }

  func endSession() throws {
#if canImport(ValidicCore)
    VLDSession.sharedInstance().endSession()
#else
    throw ApolloSyncError.platform("ValidicCore is not linked in this target.")
#endif
  }
}

private extension ApolloSyncService {
  func fetchUsernameCheck(encodedPatientUsername: String) async throws -> UsernameCheckResponse {
    let key = "YXBvbGxvdHJhbnNhY3Rpb25rZXk="
    let path = "/api/apollo-api/register-member/\(encodedPatientUsername)/\(key)"
    let url = config.ppBaseURL.appendingPathComponent(path)
    print("🌐 [DeviceSync] GET \(url.absoluteString)")
    return try await get(url: url)
  }

  func performHandshake(patientId: String, patientKey: String, deviceId: String) async throws -> HandshakeResponse {
    var components = URLComponents(url: config.ppBaseURL, resolvingAgainstBaseURL: false)!
    let model = UIDevice.current.model
    let osVersion = UIDevice.current.systemVersion
    let osName = UIDevice.current.systemName
    let deviceName = model

    components.path = "/api/handshaking/register-rpm-user/\(deviceId)/\(patientId)/\(patientKey)/HealthKit/\(deviceName)"
    components.queryItems = [
      URLQueryItem(name: "brand", value: "Apple"),
      URLQueryItem(name: "model", value: model),
      URLQueryItem(name: "osVersion", value: osVersion),
      URLQueryItem(name: "osName", value: osName),
    ]

    let url = try requiredURL(from: components)
    print("🌐 [DeviceSync] GET \(url.absoluteString)")
    return try await get(url: url)
  }

  func createOrFetchValidicUser(uidToken: String) async throws -> ValidicUserResponse {
    var createComponents = URLComponents(url: config.validicBaseURL, resolvingAgainstBaseURL: false)!
    createComponents.path = "/organizations/\(config.organizationId)/users"
    createComponents.queryItems = [URLQueryItem(name: "token", value: config.validicToken)]

    do {
      let createURL = try requiredURL(from: createComponents)
      print("🌐 [DeviceSync] POST \(createURL.absoluteString) body={uid}")
      return try await post(url: createURL, body: ["uid": uidToken])
    } catch {
      var getComponents = URLComponents(url: config.validicBaseURL, resolvingAgainstBaseURL: false)!
      getComponents.path = "/organizations/\(config.organizationId)/users/\(uidToken)"
      getComponents.queryItems = [URLQueryItem(name: "token", value: config.validicToken)]
      let getURL = try requiredURL(from: getComponents)
      print("🌐 [DeviceSync] GET \(getURL.absoluteString)")
      return try await get(url: getURL)
    }
  }

  func startValidicSession(validicUserID: String, accessToken: String) throws {
#if canImport(ValidicCore)
    guard
      let user = VLDUser(
        validicUserID: validicUserID,
        organizationID: config.organizationId,
        accessToken: accessToken
      ),
      user.isValid()
    else {
      throw ApolloSyncError.api("Invalid Validic user credentials for session start.")
    }

    VLDSession.sharedInstance().startSession(with: user)
#else
    throw ApolloSyncError.platform("ValidicCore is not linked in this target.")
#endif
  }

  func configureHealthKitAndFetchHistory() async throws {
#if canImport(ValidicHealthKit)
    let manager = VLDHealthKitManager.sharedInstance()

    manager.observeCurrentSubscriptions()

    let identifiers: [String] = [
      HKQuantityTypeIdentifier.stepCount.rawValue,
      HKQuantityTypeIdentifier.heartRate.rawValue,
      HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
      HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
      HKQuantityTypeIdentifier.bloodGlucose.rawValue,
      HKQuantityTypeIdentifier.oxygenSaturation.rawValue,
      HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
      HKWorkoutType.workoutType().identifier
    ]

    try await withCheckedThrowingContinuation { continuation in
      manager.setSubscriptionsFromIdentifiers(identifiers) {
        continuation.resume(returning: ())
      }
    }

    let endDate = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -29, to: endDate) ?? endDate

    let from = Calendar.current.dateComponents([.year, .month, .day], from: startDate)
    let to = Calendar.current.dateComponents([.year, .month, .day], from: endDate)
    let historicalSets = [
      NSNumber(value: VLDHealthKitHistoricalSetSummary.rawValue),
      NSNumber(value: VLDHealthKitHistoricalSetWorkout.rawValue)
    ]

    _ = try await withCheckedThrowingContinuation { continuation in
      manager.fetchHistoricalSets(historicalSets, from: from, to: to) { result, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        continuation.resume(returning: result ?? [:])
      }
    }
#else
    throw ApolloSyncError.platform("ValidicHealthKit is not linked in this target.")
#endif
  }

  func get<T: Decodable>(url: URL) async throws -> T {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, response) = try await session.data(for: request)
    try validate(response: response, data: data)
    if let http = response as? HTTPURLResponse {
      print("📥 [DeviceSync] \(http.statusCode) \(url.absoluteString)")
    }
    return try JSONDecoder().decode(T.self, from: data)
  }

  func post<T: Decodable>(url: URL, body: [String: String]) async throws -> T {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await session.data(for: request)
    try validate(response: response, data: data)
    if let http = response as? HTTPURLResponse {
      print("📥 [DeviceSync] \(http.statusCode) \(url.absoluteString)")
    }
    return try JSONDecoder().decode(T.self, from: data)
  }

  func validate(response: URLResponse, data: Data) throws {
    guard let http = response as? HTTPURLResponse else {
      throw ApolloSyncError.api("Invalid HTTP response.")
    }

    guard (200...299).contains(http.statusCode) else {
      let body = String(data: data, encoding: .utf8) ?? ""
      throw ApolloSyncError.api("HTTP \(http.statusCode): \(body)")
    }
  }

  func requiredURL(from components: URLComponents) throws -> URL {
    guard let url = components.url else {
      throw ApolloSyncError.api("Failed to build request URL.")
    }
    return url
  }

  func base64(_ value: String) -> String {
    Data(value.utf8).base64EncodedString()
  }
}
