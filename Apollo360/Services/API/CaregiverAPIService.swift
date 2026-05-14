//
//  CaregiverAPIService.swift
//  Apollo360
//

import Foundation

final class CaregiverAPIService {
    static let shared = CaregiverAPIService()
    private init() {}

    func fetchPatients(careGiverKey: String,
                       bearerToken: String,
                       completion: @escaping (Result<[CaregiverPatient], APIError>) -> Void) {
        APIClient.shared.caregiverPatients(careGiverKey: careGiverKey, bearerToken: bearerToken) { result in
            switch result {
            case .success(let response):
                completion(.success(response.patients))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func switchPatient(careGiverKey: String,
                       currentToken: String,
                       patientId: String,
                       bearerToken: String,
                       completion: @escaping (Result<CaregiverSwitchPatientResponse, APIError>) -> Void) {
        APIClient.shared.caregiverSwitchPatient(
            with: CaregiverSwitchPatientRequest(
                careGiverKey: careGiverKey,
                currentToken: currentToken,
                patientId: patientId
            ),
            bearerToken: bearerToken,
            completion: completion
        )
    }

    func updateNotification(patientId: Int,
                            careGiverKey: String,
                            column: String,
                            value: Int,
                            bearerToken: String,
                            completion: @escaping (Result<CaregiverNotificationResponse, APIError>) -> Void) {
        APIClient.shared.caregiverNotification(
            with: CaregiverNotificationRequest(
                patientId: patientId,
                careGiverKey: careGiverKey,
                column: column,
                value: value
            ),
            bearerToken: bearerToken,
            completion: completion
        )
    }
}
