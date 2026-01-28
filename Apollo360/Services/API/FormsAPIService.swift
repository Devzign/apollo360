//
//  FormsAPIService.swift
//  Apollo360
//
//  Created by Codex on 27/01/26.
//

import Foundation

final class FormsAPIService {
    static let shared = FormsAPIService()

    private init() {}

    func fetchPatientForms(bearerToken: String,
                           completion: @escaping (Result<[PatientFormAPIModel], APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.patientForms,
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: PatientFormsAPIResponse.self) { result in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
