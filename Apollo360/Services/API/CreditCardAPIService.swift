//
//  CreditCardAPIService.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation

struct CreditCardRequest: Encodable {
    let cardNumber: String
    let expMonth: String
    let expYear: String
    let cvv: String
}

final class CreditCardAPIService {
    static let shared = CreditCardAPIService()
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchCards(patientId: String,
                    bearerToken: String,
                    completion: @escaping (Result<[CreditCard], APIError>) -> Void) {
        client.performDataRequest(
            endpoint: APIEndpoint.billingCards(for: patientId),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let cards = try Self.decodeCards(from: data)
                    completion(.success(cards))
                } catch {
                    completion(.failure(.decodingFailed(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func addCard(patientId: String,
                 bearerToken: String,
                 payload: CreditCardRequest,
                 completion: @escaping (Result<Void, APIError>) -> Void) {
        client.performDataRequest(
            endpoint: APIEndpoint.billingCards(for: patientId),
            method: .post,
            body: payload,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteCard(patientId: String,
                    cardId: String,
                    bearerToken: String,
                    completion: @escaping (Result<Void, APIError>) -> Void) {
        client.performDataRequest(
            endpoint: APIEndpoint.billingCard(for: patientId, cardId: cardId),
            method: .delete,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private static func decodeCards(from data: Data) throws -> [CreditCard] {
        let decoder = JSONDecoder()
        if let wrapper = try? decoder.decode(CreditCardListResponse.self, from: data) {
            return wrapper.cards
        }
        if let cards = try? decoder.decode([CreditCard].self, from: data) {
            return cards
        }
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Unable to decode credit cards"))
    }
}
