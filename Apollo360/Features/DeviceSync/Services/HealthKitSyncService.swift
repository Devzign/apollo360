import Foundation
import HealthKit

protocol ValidicSessionManaging {
    func startSession(configuration: DeviceSyncConfiguration) async throws
}

final class ValidicSessionManager: ValidicSessionManaging {
    func startSession(configuration: DeviceSyncConfiguration) async throws {
        guard configuration.isReadyForSession else {
            throw DeviceSyncError.invalidConfiguration(
                "Missing Validic session values. Inject userID, organizationID and accessToken before sync."
            )
        }

        // Integrate the Validic iOS SDK session start here.
        // Example (pseudo):
        // VLDSession.shared.start(userID: configuration.validicSessionUserID,
        //                         organizationID: configuration.validicSessionOrganizationID,
        //                         accessToken: configuration.validicSessionAccessToken)
    }
}

protocol HealthKitSyncServicing {
    func performThirtyDaySync(configuration: DeviceSyncConfiguration) async throws -> HealthKitSyncResult
}

final class HealthKitSyncService: HealthKitSyncServicing {
    private let healthStore: HKHealthStore
    private let validicSessionManager: ValidicSessionManaging

    init(healthStore: HKHealthStore = HKHealthStore(),
         validicSessionManager: ValidicSessionManaging = ValidicSessionManager()) {
        self.healthStore = healthStore
        self.validicSessionManager = validicSessionManager
    }

    func performThirtyDaySync(configuration: DeviceSyncConfiguration) async throws -> HealthKitSyncResult {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw DeviceSyncError.healthKitNotAvailable
        }

        try await validicSessionManager.startSession(configuration: configuration)
        try await requestAuthorization()
        try await configureSubscriptions()

        async let summaries = fetchActivitySummaries(lastDays: 30)
        async let workouts = fetchWorkouts(lastDays: 30)

        let summarySamples = try await summaries
        let workoutSamples = try await workouts

        // Add upload pipeline here if your Validic SDK integration requires manual pushes.
        return HealthKitSyncResult(
            activitySummaryCount: summarySamples.count,
            workoutCount: workoutSamples.count
        )
    }

    private func requestAuthorization() async throws {
        var readTypes = Set<HKObjectType>()
        readTypes.insert(HKObjectType.activitySummaryType())
        readTypes.insert(HKObjectType.workoutType())
        if let step = HKObjectType.quantityType(forIdentifier: .stepCount) {
            readTypes.insert(step)
        }
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            readTypes.insert(activeEnergy)
        }
        if let distance = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning) {
            readTypes.insert(distance)
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if success {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: DeviceSyncError.invalidResponse)
                }
            }
        }
    }

    private func configureSubscriptions() async throws {
        var sampleTypes: [HKSampleType] = [HKObjectType.workoutType()]
        if let step = HKObjectType.quantityType(forIdentifier: .stepCount) {
            sampleTypes.append(step)
        }
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            sampleTypes.append(activeEnergy)
        }

        for sampleType in sampleTypes {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.enableBackgroundDelivery(for: sampleType, frequency: .hourly) { success, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    if success {
                        continuation.resume(returning: ())
                    } else {
                        continuation.resume(throwing: DeviceSyncError.invalidResponse)
                    }
                }
            }
        }
    }

    private func fetchActivitySummaries(lastDays: Int) async throws -> [HKActivitySummary] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -lastDays, to: endDate) else {
            return []
        }

        let startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: startComponents,
                                          end: endComponents)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKActivitySummaryQuery(predicate: predicate) { _, summaries, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: summaries ?? [])
            }
            healthStore.execute(query)
        }
    }

    private func fetchWorkouts(lastDays: Int) async throws -> [HKWorkout] {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -lastDays, to: endDate) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: .workoutType(),
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sort]) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }
}
