//
//  RecordsAPIService.swift
//  Apollo360
//
//  Created by Codex on 07/04/26.
//

import Foundation

final class RecordsAPIService {
    static let shared = RecordsAPIService()

    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchRecords(patientId: String,
                      bearerToken: String,
                      completion: @escaping (Result<PatientRecordsResponse, APIError>) -> Void) {
        client.request(
            endpoint: APIEndpoint.patientRecords(for: patientId),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"],
            responseType: PatientRecordsResponse.self,
            completion: completion
        )
    }

    func fetchVisitSummary(patientId: String,
                           encounterId: Int,
                           bearerToken: String,
                           completion: @escaping (Result<DoctorVisitSummaryResponse, APIError>) -> Void) {
        client.request(
            endpoint: APIEndpoint.patientVisitSummary(for: patientId, encounterId: encounterId),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"],
            responseType: DoctorVisitSummaryResponse.self,
            completion: completion
        )
    }
}
