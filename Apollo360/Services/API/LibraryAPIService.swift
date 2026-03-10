//
//  LibraryAPIService.swift
//  Apollo360
//
//  Created by Codex on 05/03/26.
//

import Foundation

final class LibraryAPIService {
    static let shared = LibraryAPIService()
    private init() {}

    private func authHeaders(token: String) -> [String: String] {
        [
            "Accept": "application/json",
            "Authorization": "Bearer \(token)"
        ]
    }

    func fetchArticles(type: String,
                       search: String,
                       filter: String,
                       page: Int,
                       limit: Int,
                       token: String,
                       completion: @escaping (Result<ArticlesAPIResponse, APIError>) -> Void) {
        let endpoint = APIEndpoint.articles(
            type: type,
            search: search,
            filter: filter,
            page: page,
            limit: limit
        )
        APIClient.shared.request(
            endpoint: endpoint,
            method: .get,
            headers: authHeaders(token: token),
            responseType: ArticlesAPIResponse.self,
            completion: completion
        )
    }

    func fetchArticleDetails(id: Int,
                             token: String,
                             completion: @escaping (Result<ArticleDetailResponse, APIError>) -> Void) {
        APIClient.shared.request(
            endpoint: APIEndpoint.articleDetails(id: id),
            method: .get,
            headers: authHeaders(token: token),
            responseType: ArticleDetailResponse.self,
            completion: completion
        )
    }

    func setArticleSaved(id: Int,
                         value: Bool,
                         token: String,
                         completion: @escaping (Result<Void, APIError>) -> Void) {
        struct SavePayload: Encodable {
            let value: Bool
        }

        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.articleSave(id: id),
            method: .patch,
            body: SavePayload(value: value),
            headers: authHeaders(token: token)
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(.noData):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
