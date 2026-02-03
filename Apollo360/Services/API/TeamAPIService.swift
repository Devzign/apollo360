//
//  TeamAPIService.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation

final class TeamAPIService {
    static let shared = TeamAPIService()
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchTeamPage(bearerToken: String,
                       completion: @escaping (Result<String, APIError>) -> Void) {
        client.performDataRequest(
            endpoint: APIEndpoint.team,
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
