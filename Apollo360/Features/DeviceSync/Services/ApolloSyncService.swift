import Foundation
import UIKit

#if canImport(ValidicCore) && canImport(ValidicHealthKit)
import ValidicCore
import ValidicHealthKit
import HealthKit
#endif

struct ApolloSyncConfig {
  let ppBaseURL: URL
  let memberLookupBaseURL: URL
  let validicBaseURL: URL
  let organizationId: String
  let validicToken: String
  static let fallbackValidicOrganizationId = "6232413757463e0001806968"

  static func fromInfoPlist() throws -> ApolloSyncConfig {
    let bundle = Bundle.main

    guard
      let ppBase = bundle.object(forInfoDictionaryKey: "PP_BASE_URL") as? String,
      let validicBase = bundle.object(forInfoDictionaryKey: "VALIDIC_URL_V2") as? String,
      let token = bundle.object(forInfoDictionaryKey: "VALIDIC_TOKEN") as? String,
      let ppURL = URL(string: ppBase),
      let validicURL = URL(string: validicBase)
    else {
      throw ApolloSyncError.configuration("Missing one or more required Info.plist values: PP_BASE_URL, VALIDIC_URL_V2, VALIDIC_TOKEN")
    }

    let organizationCandidates = [
      bundle.object(forInfoDictionaryKey: "ORGANISATION_ID") as? String,
      bundle.object(forInfoDictionaryKey: "VALIDIC_ORGANIZATION_ID") as? String,
      bundle.object(forInfoDictionaryKey: "VALIDIC_ORG_ID") as? String
    ]
      .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }

    let organizationId = organizationCandidates.first ?? fallbackValidicOrganizationId

    let validicToken = token.trimmingCharacters(in: .whitespacesAndNewlines)

    return ApolloSyncConfig(
      ppBaseURL: ppURL,
      memberLookupBaseURL: ppURL,
      validicBaseURL: validicURL,
      organizationId: organizationId,
      validicToken: validicToken
    )
  }
}

enum ApolloSyncError: LocalizedError {
  case configuration(String)
  case api(String)
  case platform(String)
  case auth(String)

  var errorDescription: String? {
    switch self {
    case .configuration(let message), .api(let message), .platform(let message), .auth(let message):
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

struct ValidateRPMUserResponse: Decodable {
  let status: Bool
}

struct HandshakeResponse: Decodable {
  let status: Bool
  let message: String
  let token: String

  var success: Bool { status }
}

struct ValidicCreateUserErrorResponse: Decodable {
  let errors: [String: [String]]?

  var indicatesExistingUser: Bool {
    errors?.values.flatMap { $0 }.contains(where: { $0.localizedCaseInsensitiveContains("already exists") }) == true
  }
}

struct ValidicUserResponse: Codable {
  struct Mobile: Codable {
    let token: String
  }

  struct Marketplace: Codable {
    let token: String?
    let url: String
  }

  struct Source: Codable {
    let type: String
    let connected_at: String
    let last_processed_at: String
  }

  struct Location: Codable {
    let timezone: String?
    let country_code: String?
  }

  let id: String
  let uid: String
  let marketplace: Marketplace
  let mobile: Mobile
  let location: Location?
  let sources: [Source]?
  let status: String?
  let created_at: String?
  let updated_at: String?
}

final class ApolloSyncService {
  private let config: ApolloSyncConfig
  private let session: URLSession
  private let userDefaults: UserDefaults

  init(config: ApolloSyncConfig, session: URLSession = .shared, userDefaults: UserDefaults = .standard) {
    self.config = config
    self.session = session
    self.userDefaults = userDefaults
  }

  func runFullSync(encodedPatientUsername: String, deviceId: String) async throws -> ValidicUserResponse {
    print("📲 [DeviceSync] runFullSync started | deviceId=\(deviceId)")
    guard !encodedPatientUsername.isEmpty else {
      throw ApolloSyncError.auth("Apollo username is missing from the current session. Log in again before syncing.")
    }

    let handshake = try await requestHandshake(
      encodedPatientUsername: encodedPatientUsername,
      deviceId: deviceId,
      bearerToken: resolvedApolloAccessToken(explicitAccessToken: nil)
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

    try await configureHealthKitAndFetchHistory(validicUser: validicUser)
    print("✅ [DeviceSync] HealthKit subscriptions/history done")

    return validicUser
  }

  func runFullSync(encodedPatientUsername: String,
                   deviceId: String,
                   dateOfBirth: String,
                   phoneNumber: String,
                   otp: String) async throws -> ValidicUserResponse {
    guard !encodedPatientUsername.isEmpty else {
      throw ApolloSyncError.auth("Apollo username is missing from the current session. Log in again before syncing.")
    }

    let login = try await loginPatient(
      dateOfBirth: dateOfBirth,
      phoneNumber: phoneNumber,
      otp: otp
    )

    guard let accessToken = login.accessToken?.trimmingCharacters(in: .whitespacesAndNewlines),
          !accessToken.isEmpty else {
      throw ApolloSyncError.auth("Apollo patient-login did not return an access token.")
    }

    let handshake = try await requestHandshake(
      encodedPatientUsername: encodedPatientUsername,
      deviceId: deviceId,
      bearerToken: accessToken
    )

    guard handshake.success else {
      throw ApolloSyncError.api(handshake.message)
    }

    let validicUser = try await createOrFetchValidicUser(uidToken: handshake.token)

    try startValidicSession(
      validicUserID: validicUser.id,
      accessToken: validicUser.mobile.token
    )

    try await configureHealthKitAndFetchHistory(validicUser: validicUser)

    return validicUser
  }

  /// Handshake + Validic user registration only — no HealthKit upload.
  /// Fast path for dashboard header. Full HealthKit sync is in DeviceSyncView.
  func registerValidicUser(encodedPatientUsername: String, deviceId: String) async throws -> ValidicUserResponse {
    guard !encodedPatientUsername.isEmpty else {
      throw ApolloSyncError.auth("Apollo username is missing. Log in again before syncing.")
    }
    let handshake = try await requestHandshake(
      encodedPatientUsername: encodedPatientUsername,
      deviceId: deviceId,
      bearerToken: resolvedApolloAccessToken(explicitAccessToken: nil)
    )
    guard handshake.success else {
      throw ApolloSyncError.api(handshake.message)
    }
    let validicUser = try await createOrFetchValidicUser(uidToken: handshake.token)
    print("✅ [DeviceSync] Validic user registered | id=\(validicUser.id) sources=\(validicUser.sources?.count ?? 0)")
    try startValidicSession(validicUserID: validicUser.id, accessToken: validicUser.mobile.token)
    return validicUser
  }

  func performHandshakeForCurrentSession(encodedPatientUsername: String,
                                         deviceId: String,
                                         bearerToken: String? = nil) async throws -> HandshakeResponse {
    guard !encodedPatientUsername.isEmpty else {
      throw ApolloSyncError.auth("Apollo username is missing from the current session. Log in again before syncing.")
    }

    let handshake = try await requestHandshake(
      encodedPatientUsername: encodedPatientUsername,
      deviceId: deviceId,
      bearerToken: resolvedApolloAccessToken(explicitAccessToken: bearerToken)
    )

    guard handshake.success else {
      throw ApolloSyncError.api(handshake.message)
    }

    return handshake
  }

  func refreshValidicSources(uidToken: String) async throws -> ValidicUserResponse {
    var components = URLComponents(url: config.validicBaseURL, resolvingAgainstBaseURL: false)!
    components.path = "/organizations/\(config.organizationId)/users/\(uidToken)"
    components.queryItems = [URLQueryItem(name: "token", value: config.validicToken)]
    return try await get(url: try requiredURL(from: components))
  }

  func startSession(for user: ValidicUserResponse) throws {
    try startValidicSession(validicUserID: user.id, accessToken: user.mobile.token)
  }

  func syncHistoricalHealthKitData(validicUser: ValidicUserResponse? = nil) async throws {
    try await configureHealthKitAndFetchHistory(validicUser: validicUser)
  }

  func endSession() {
#if canImport(ValidicCore)
    VLDSession.sharedInstance().endSession()
#else
    print("⚠️ [DeviceSync] ValidicCore SDK not linked — endSession skipped.")
#endif
  }
}

private extension ApolloSyncService {
  func loginPatient(dateOfBirth: String, phoneNumber: String, otp: String) async throws -> PatientLoginResponse {
    let url = ppURL(path: "/api/patient-login")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.httpBody = try JSONSerialization.data(withJSONObject: [
      "date_of_birth": dateOfBirth,
      "phone_number": phoneNumber,
      "otp": Int(otp) ?? 0
    ])

    let (data, response) = try await perform(request: request, endpointLabel: "Apollo patient-login")
    try validate(response: response, data: data)
    return try JSONDecoder().decode(PatientLoginResponse.self, from: data)
  }

  func requestHandshake(encodedPatientUsername: String,
                        deviceId: String,
                        bearerToken: String) async throws -> HandshakeResponse {
    let usernameCheck = try await fetchUsernameCheck(
      encodedPatientUsername: encodedPatientUsername,
      bearerToken: bearerToken
    )
    print("✅ [DeviceSync] usernameCheck return_code=\(usernameCheck.return_code)")

    guard usernameCheck.return_code == "400" else {
      throw ApolloSyncError.api("usernameCheck returned code \(usernameCheck.return_code). Expected 400 for handshake flow.")
    }

    guard let patientIdRaw = usernameCheck.patient_id, let patientKeyRaw = usernameCheck.patient_key else {
      throw ApolloSyncError.api("usernameCheck did not return patient_id or patient_key.")
    }

    let encodedPatientId = base64(patientIdRaw)
    let encodedPatientKey = base64(patientKeyRaw)

    let validation = try await validateRPMUser(
      patientId: encodedPatientId,
      patientKey: encodedPatientKey,
      bearerToken: bearerToken
    )
    print("✅ [DeviceSync] validateRPMUser status=\(validation.status)")

    guard validation.status else {
      throw ApolloSyncError.api("validate-rpm-user returned status=false.")
    }

    return try await performHandshake(
      patientId: encodedPatientId,
      patientKey: encodedPatientKey,
      deviceId: deviceId,
      bearerToken: bearerToken
    )
  }

  func fetchUsernameCheck(encodedPatientUsername: String, bearerToken: String) async throws -> UsernameCheckResponse {
    let key = "YXBvbGxvdHJhbnNhY3Rpb25rZXk="
    let path = "/api/register-member/\(encodedPatientUsername)/\(key)"
    let url = memberLookupURL(path: path)
    print("🌐 [DeviceSync] GET \(url.absoluteString)")
    return try await get(url: url, bearerToken: nil, includeApolloHeaders: false)
  }

  func validateRPMUser(patientId: String, patientKey: String, bearerToken: String) async throws -> ValidateRPMUserResponse {
    let url = ppURL(path: "/api/validate-rpm-user/\(patientId)/\(patientKey)")
    print("🌐 [DeviceSync] GET \(url.absoluteString)")
    return try await get(url: url, bearerToken: nil, includeApolloHeaders: false)
  }

  func performHandshake(patientId: String, patientKey: String, deviceId: String, bearerToken: String) async throws -> HandshakeResponse {
    var components = ppURLComponents()
    let model = UIDevice.current.model
    let osVersion = UIDevice.current.systemVersion
    let osName = UIDevice.current.systemName
    let deviceName = model

    components.path = "/api/register-rpm-user/\(deviceId)/\(patientId)/\(patientKey)/HealthKit/\(deviceName)"
    components.queryItems = [
      URLQueryItem(name: "brand", value: "Apple"),
      URLQueryItem(name: "model", value: model),
      URLQueryItem(name: "osVersion", value: osVersion),
      URLQueryItem(name: "osName", value: osName),
    ]

    let url = try requiredURL(from: components)
    print("🌐 [DeviceSync] GET \(url.absoluteString)")
    return try await get(url: url, bearerToken: nil, includeApolloHeaders: false)
  }

  func createOrFetchValidicUser(uidToken: String) async throws -> ValidicUserResponse {
    try ensureValidicConfiguration()

    var createComponents = URLComponents(url: config.validicBaseURL, resolvingAgainstBaseURL: false)!
    createComponents.path = "/organizations/\(config.organizationId)/users"
    createComponents.queryItems = [URLQueryItem(name: "token", value: config.validicToken)]

    do {
      let createURL = try requiredURL(from: createComponents)
      print("🌐 [DeviceSync] POST \(createURL.absoluteString) body={uid}")
      return try await post(url: createURL, body: ["uid": uidToken])
    } catch {
      if let createError = error as? ApolloSyncError,
         case .api(let message) = createError,
         let data = message.data(using: .utf8),
         let response = try? JSONDecoder().decode(ValidicCreateUserErrorResponse.self, from: data),
         !response.indicatesExistingUser {
        throw error
      }

      var getComponents = URLComponents(url: config.validicBaseURL, resolvingAgainstBaseURL: false)!
      getComponents.path = "/organizations/\(config.organizationId)/users/\(uidToken)"
      getComponents.queryItems = [URLQueryItem(name: "token", value: config.validicToken)]
      let getURL = try requiredURL(from: getComponents)
      print("🌐 [DeviceSync] GET \(getURL.absoluteString)")
      return try await get(url: getURL)
    }
  }

  func startValidicSession(validicUserID: String, accessToken: String) throws {
    try ensureValidicConfiguration()
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
    print("⚠️ [DeviceSync] ValidicCore SDK not linked — session start skipped.")
#endif
  }

  func configureHealthKitAndFetchHistory(validicUser: ValidicUserResponse? = nil) async throws {
#if canImport(ValidicHealthKit)
    let manager = VLDHealthKitManager.sharedInstance()

    manager.observeCurrentSubscriptions()

    let identifiers = healthKitSubscriptionIdentifiers()

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
    guard let validicUser else {
      print("⚠️ [DeviceSync] No Validic user available — HealthKit upload skipped.")
      return
    }
    let uploader = ValidicMobileInformService(
      organizationId: config.organizationId,
      userId: validicUser.id,
      mobileToken: validicUser.mobile.token,
      validicUser: validicUser
    )
    do {
      try await uploader.uploadThirtyDayHistory()
    } catch ValidicUploadError.sourceNotConnected {
      // Apple Health not connected yet — not a fatal error, just inform.
      print("⚠️ [DeviceSync] Apple Health not connected in Validic. User must tap 'Manage your devices' first.")
    }
#endif
  }

  func healthKitSubscriptionIdentifiers() -> [String] {
#if canImport(ValidicHealthKit)
    [
      HKQuantityTypeIdentifier.stepCount.rawValue,
      HKQuantityTypeIdentifier.heartRate.rawValue,
      HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
      HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
      HKQuantityTypeIdentifier.bloodGlucose.rawValue,
      HKQuantityTypeIdentifier.oxygenSaturation.rawValue,
      HKCategoryTypeIdentifier.sleepAnalysis.rawValue,
      HKWorkoutType.workoutType().identifier
    ]
#else
    []
#endif
  }

  func get<T: Decodable>(url: URL,
                         bearerToken: String? = nil,
                         includeApolloHeaders: Bool = true,
                         endpointLabel: String? = nil) async throws -> T {
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    if includeApolloHeaders {
      applyApolloAuthHeaders(to: &request, bearerToken: bearerToken)
    }

    let (data, response) = try await perform(request: request, endpointLabel: endpointLabel ?? url.absoluteString)
    try validate(response: response, data: data)
    return try JSONDecoder().decode(T.self, from: data)
  }

  func post<T: Decodable>(url: URL,
                          body: [String: String],
                          endpointLabel: String? = nil) async throws -> T {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await perform(request: request, endpointLabel: endpointLabel ?? url.absoluteString)
    try validate(response: response, data: data)
    return try JSONDecoder().decode(T.self, from: data)
  }

  func perform(request: URLRequest, endpointLabel: String) async throws -> (Data, URLResponse) {
    APILogger.logRequest(
      endpoint: endpointLabel,
      url: request.url?.absoluteString ?? "n/a",
      method: request.httpMethod ?? "GET",
      headers: request.allHTTPHeaderFields,
      body: request.httpBody
    )

    do {
      let result = try await session.data(for: request)
      if let http = result.1 as? HTTPURLResponse {
        APILogger.logResponse(
          endpoint: endpointLabel,
          url: request.url?.absoluteString ?? "n/a",
          statusCode: http.statusCode,
          data: result.0
        )
      }
      return result
    } catch {
      APILogger.logError(
        endpoint: endpointLabel,
        url: request.url?.absoluteString ?? "n/a",
        error: error
      )
      throw error
    }
  }

  func validate(response: URLResponse, data: Data) throws {
    guard let http = response as? HTTPURLResponse else {
      print("❌ [DeviceSync] Invalid HTTP response")
      throw ApolloSyncError.api("Invalid HTTP response.")
    }

    guard (200...299).contains(http.statusCode) else {
      let body = String(data: data, encoding: .utf8) ?? ""
      print("❌ [DeviceSync] HTTP \(http.statusCode) body=\(body)")
      throw ApolloSyncError.api("HTTP \(http.statusCode): \(body)")
    }
  }

  func requiredURL(from components: URLComponents) throws -> URL {
    guard let url = components.url else {
      throw ApolloSyncError.api("Failed to build request URL.")
    }
    return url
  }

  func ensureValidicConfiguration() throws {
    if config.organizationId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      throw ApolloSyncError.configuration("Validic organization id is empty.")
    }
    if config.validicToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      throw ApolloSyncError.configuration("VALIDIC_TOKEN is empty.")
    }
  }

  func ppURL(path: String) -> URL {
    url(from: config.ppBaseURL, path: path)
  }

  func memberLookupURL(path: String) -> URL {
    url(from: config.memberLookupBaseURL, path: path)
  }

  func ppURLComponents() -> URLComponents {
    URLComponents(url: config.ppBaseURL, resolvingAgainstBaseURL: false)!
  }

  func url(from baseURL: URL, path: String) -> URL {
    let cleanedPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
    return baseURL.appendingPathComponent(cleanedPath)
  }

  func base64(_ value: String) -> String {
    Data(value.utf8).base64EncodedString()
  }

  func applyApolloAuthHeaders(to request: inout URLRequest, bearerToken: String?) {
    guard let bearerToken, !bearerToken.isEmpty else { return }
    request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
    request.setValue(bearerToken, forHTTPHeaderField: "apollo-md-access-token")
  }

  func resolvedApolloAccessToken(explicitAccessToken: String?) throws -> String {
    let accessToken = (explicitAccessToken ?? userDefaults.string(forKey: "Apollo360.accessToken"))?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !accessToken.isEmpty else {
      throw ApolloSyncError.auth("Apollo access token is missing. Log in again before starting device sync.")
    }
    return accessToken
  }
}
