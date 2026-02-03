//
//  ContactsAPIService.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation

enum ContactType: String {
    case caregiver
    case healthcareProvider = "healthcare-provider"
}

final class ContactsAPIService {
    static let shared = ContactsAPIService()
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchContacts(bearerToken: String, completion: @escaping (Result<ContactsResponse, APIError>) -> Void) {
        client.performDataRequest(
            endpoint: APIEndpoint.myContacts,
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(ContactsResponse.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(.decodingFailed(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func addCaregiver(bearerToken: String, payload: CaregiverInput, completion: @escaping (Result<Void, APIError>) -> Void) {
        client.performDataRequest(
            endpoint: APIEndpoint.myContactsCaregiver,
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

    func addHealthcareProvider(bearerToken: String, payload: HealthcareProviderInput, completion: @escaping (Result<Void, APIError>) -> Void) {
        client.performDataRequest(
            endpoint: APIEndpoint.myContactsHealthcareProvider,
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

    func deleteContact(_ key: String, type: ContactType, bearerToken: String, completion: @escaping (Result<Void, APIError>) -> Void) {
        let endpoint = "\(APIEndpoint.myContactsContact(key: key))?type=\(type.rawValue)"
        client.performDataRequest(
            endpoint: endpoint,
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

    func consentFormURL(for key: String, type: String, formType: String, contactType: String) -> URL? {
        URL(string: APIConfiguration.currentEnvironment.baseURLString)?
            .appendingPathComponent(APIEndpoint.myContactsConsentForm(key: key, type: type, formType: formType, contactType: contactType))
    }
}
