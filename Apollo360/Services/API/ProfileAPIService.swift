//
//  ProfileAPIService.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation

final class ProfileAPIService {
    static let shared = ProfileAPIService()
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchProfile(bearerToken: String,
                      completion: @escaping (Result<Profile, APIError>) -> Void) {
        client.performDataRequest(
            endpoint: APIEndpoint.profile,
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let profile = try JSONDecoder().decode(Profile.self, from: data)
                    completion(.success(profile))
                } catch {
                    completion(.failure(.decodingFailed(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
