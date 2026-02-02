//
//  LegalAPIService.swift
//  Apollo360
//
//  Created by Amit Sinha on 02/02/26.
//

import Foundation

final class LegalAPIService {
    static let shared = LegalAPIService()
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchTermsOfUse(bearerToken: String,
                         completion: @escaping (Result<String, APIError>) -> Void) {
        fetchHTML(endpoint: APIEndpoint.termsOfUse, bearerToken: bearerToken, completion: completion)
    }

    func fetchPrivacyPolicy(bearerToken: String,
                            completion: @escaping (Result<String, APIError>) -> Void) {
        fetchHTML(endpoint: APIEndpoint.privacyPolicy, bearerToken: bearerToken, completion: completion)
    }

    private func fetchHTML(endpoint: String,
                           bearerToken: String,
                           completion: @escaping (Result<String, APIError>) -> Void) {
        client.performDataRequest(
            endpoint: endpoint,
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                let html = String(data: data, encoding: .utf8) ?? ""
                completion(.success(html))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
