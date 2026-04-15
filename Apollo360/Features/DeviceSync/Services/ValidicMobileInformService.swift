import Foundation
import HealthKit
import UIKit

/// Reads HealthKit samples and uploads them to the Validic Mobile Inform API.
/// Reference endpoint:
///   POST https://mobile-inform.prod.validic.com/records/measurement
///        ?organization_id={org_id}&user_id={user_id}
///   Headers: X-Validic-Mobile-Token, Validic-Version: 2015-10-01
final class ValidicMobileInformService {

  private let organizationId: String
  private let userId: String
  private let mobileToken: String
  private let validicUser: ValidicUserResponse
  private let baseURL: URL
  private let urlSession: URLSession
  private let healthStore = HKHealthStore()

  init(
    validicUser: ValidicUserResponse,
    mobileInformBaseURL: URL = URL(string: "https://mobile-inform.prod.validic.com")!,
    urlSession: URLSession = .shared
  ) {
    self.validicUser = validicUser
    self.organizationId = validicUser.marketplace.url.isEmpty ? "" : {
      // Extract org id from the config — passed separately below
      ""
    }()
    self.userId = validicUser.id
    self.mobileToken = validicUser.mobile.token
    self.baseURL = mobileInformBaseURL
    self.urlSession = urlSession
  }

  init(
    organizationId: String,
    userId: String,
    mobileToken: String,
    validicUser: ValidicUserResponse,
    mobileInformBaseURL: URL = URL(string: "https://mobile-inform.prod.validic.com")!,
    urlSession: URLSession = .shared
  ) {
    self.organizationId = organizationId
    self.userId = userId
    self.mobileToken = mobileToken
    self.validicUser = validicUser
    self.baseURL = mobileInformBaseURL
    self.urlSession = urlSession
  }

  // MARK: - Public

  /// Uploads HealthKit data ONLY if Apple Health source is connected in Validic.
  /// Stops immediately on the first failed upload (circuit breaker).
  func uploadThirtyDayHistory() async throws {
    // 1. Pre-check: Apple Health must be connected as a Validic source.
    let sources = validicUser.sources ?? []
    let isAppleHealthConnected = sources.contains { $0.type.lowercased().contains("apple_health") || $0.type.lowercased().contains("healthkit") }

    guard isAppleHealthConnected else {
      print("⚠️ [ValidicMobileInform] Apple Health is NOT connected in Validic (sources=\(sources.map(\.type))).")
      print("⚠️ [ValidicMobileInform] Open 'Manage your devices' → connect Apple Health → then sync.")
      throw ValidicUploadError.sourceNotConnected
    }

    guard HKHealthStore.isHealthDataAvailable() else {
      print("⚠️ [ValidicMobileInform] HealthKit not available on this device.")
      return
    }

    try await requestAuthorization()

    let endDate   = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate

    print("📊 [ValidicMobileInform] Apple Health connected ✅ — uploading HealthKit data \(startDate) → \(endDate)")

    // 2. Upload sequentially so the circuit breaker can halt everything on 404.
    let stopped = await fetchAndUpload(.oxygenSaturation, from: startDate, to: endDate,
                                       metricType: "spo2", unitName: "percent",
                                       hkUnit: .percent(), scale: 100.0)
    guard !stopped else { return }

    let stopped2 = await fetchAndUpload(.heartRate, from: startDate, to: endDate,
                                        metricType: "heart_rate", unitName: "beats_per_min",
                                        hkUnit: HKUnit(from: "count/min"), scale: 1.0)
    guard !stopped2 else { return }

    await fetchAndUpload(.stepCount, from: startDate, to: endDate,
                         metricType: "steps", unitName: "count",
                         hkUnit: .count(), scale: 1.0)

    print("✅ [ValidicMobileInform] Upload complete.")
  }

  // MARK: - HealthKit Authorization

  private func requestAuthorization() async throws {
    let readTypes: Set<HKObjectType> = [
      HKQuantityType(.oxygenSaturation),
      HKQuantityType(.heartRate),
      HKQuantityType(.stepCount)
    ]

    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      healthStore.requestAuthorization(toShare: nil, read: readTypes) { _, error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
    }
  }

  // MARK: - Fetch + Upload
  // Returns true if upload was stopped by circuit breaker (first failure).

  @discardableResult
  private func fetchAndUpload(
    _ identifier: HKQuantityTypeIdentifier,
    from startDate: Date,
    to endDate: Date,
    metricType: String,
    unitName: String,
    hkUnit: HKUnit,
    scale: Double
  ) async -> Bool {
    guard let quantityType = HKQuantityType.quantityType(forIdentifier: identifier) else { return false }

    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

    do {
      let samples: [HKSample] = try await withCheckedThrowingContinuation { continuation in
        let query = HKSampleQuery(
          sampleType: quantityType,
          predicate: predicate,
          limit: HKObjectQueryNoLimit,
          sortDescriptors: [sort]
        ) { _, results, error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: results ?? [])
          }
        }
        healthStore.execute(query)
      }

      print("📲 [ValidicMobileInform] \(metricType) — \(samples.count) samples")

      for sample in samples {
        guard let qty = sample as? HKQuantitySample else { continue }
        let rawValue = qty.quantity.doubleValue(for: hkUnit)
        let value    = rawValue * scale
        let success  = await upload(sample: qty, metricType: metricType, unitName: unitName, value: value)
        if !success {
          // Circuit breaker: first failure → stop entire metric upload.
          print("🛑 [ValidicMobileInform] Stopping \(metricType) — first upload failed. Check source connection.")
          return true   // stopped = true
        }
      }
    } catch {
      print("❌ [ValidicMobileInform] HealthKit query failed for \(metricType): \(error.localizedDescription)")
    }
    return false  // stopped = false
  }

  // MARK: - Upload Single Measurement
  // Returns true on HTTP 2xx, false on any error.

  private func upload(
    sample: HKQuantitySample,
    metricType: String,
    unitName: String,
    value: Double
  ) async -> Bool {
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime]

    let logId     = sample.uuid.uuidString
    let startTime = iso.string(from: sample.startDate)
    let endTime   = iso.string(from: sample.endDate)
    let utcOffset = TimeZone.current.secondsFromGMT(for: sample.startDate)

    let deviceModel: String
    let deviceSourceId: String
    if let device = sample.device {
      deviceModel    = device.model ?? UIDevice.current.model
      deviceSourceId = "com.apple.health.\(device.name ?? logId)"
    } else {
      deviceModel    = UIDevice.current.model
      deviceSourceId = "com.apple.health.\(UIDevice.current.identifierForVendor?.uuidString ?? logId)"
    }

    let payload: [String: Any] = [
      "end_time": endTime,
      "log_id":   logId,
      "metrics": [
        [
          "origin": "unknown",
          "type":   metricType,
          "unit":   unitName,
          "value":  value
        ]
      ],
      "offset_origin": "source",
      "source": [
        "device": [
          "diagnostics": [
            ["type": "mobile_device_manufacturer",    "unit": "n/a", "value": "Apple"],
            ["type": "mobile_device_model_number",    "unit": "n/a", "value": UIDevice.current.model],
            ["type": "operating_system",              "unit": "n/a", "value": UIDevice.current.systemName],
            ["type": "operating_system_version",      "unit": "n/a", "value": UIDevice.current.systemVersion]
          ],
          "id":           deviceSourceId,
          "manufacturer": "Apple Inc.",
          "model":        deviceModel
        ],
        "type": "apple_health"
      ],
      "start_time": startTime,
      "type":       "measurement",
      "utc_offset": utcOffset
    ]

    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
    components.path = "/records/measurement"
    components.queryItems = [
      URLQueryItem(name: "organization_id", value: organizationId),
      URLQueryItem(name: "user_id",         value: userId)
    ]

    guard let url = components.url else { return false }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("2015-10-01",        forHTTPHeaderField: "Validic-Version")
    request.setValue(mobileToken,         forHTTPHeaderField: "X-Validic-Mobile-Token")

    do {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)

      #if DEBUG
      APILogger.logRequest(
        endpoint: "ValidicMobileInform/\(metricType)",
        url: url.absoluteString,
        method: "POST",
        headers: request.allHTTPHeaderFields,
        body: request.httpBody
      )
      #endif

      let (data, response) = try await urlSession.data(for: request)
      if let http = response as? HTTPURLResponse {
        #if DEBUG
        APILogger.logResponse(
          endpoint: "ValidicMobileInform/\(metricType)",
          url: url.absoluteString,
          statusCode: http.statusCode,
          data: data
        )
        #endif
        let succeeded = (200...299).contains(http.statusCode)
        if succeeded {
          print("✅ [ValidicMobileInform] \(metricType) log_id=\(logId) → HTTP \(http.statusCode)")
        } else {
          print("❌ [ValidicMobileInform] \(metricType) HTTP \(http.statusCode) — source not connected or token invalid")
        }
        return succeeded
      }
      return false
    } catch {
      print("❌ [ValidicMobileInform] Upload failed \(metricType) log_id=\(logId): \(error.localizedDescription)")
      return false
    }
  }
}

// MARK: - Errors

enum ValidicUploadError: LocalizedError {
  case sourceNotConnected

  var errorDescription: String? {
    switch self {
    case .sourceNotConnected:
      return "Apple Health is not connected in Validic yet. Tap 'Manage your devices' to connect it first."
    }
  }
}
