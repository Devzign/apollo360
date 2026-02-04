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

    func uploadProfilePicture(bearerToken: String,
                              imageData: Data,
                              mimeType: String,
                              completion: @escaping (Result<Void, APIError>) -> Void) {
        let url = APIConfiguration.baseURL.appendingPathComponent(APIEndpoint.profilePicture)
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.put.rawValue
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.httpBody = createMultipartBody(fieldName: "image",
                                               fileName: "profile-picture.\(mimeType.fileExtension)",
                                               mimeType: mimeType,
                                               data: imageData,
                                               boundary: boundary)

        #if DEBUG
        APILogger.logRequest(endpoint: APIEndpoint.profilePicture, method: HTTPMethod.put.rawValue, headers: request.allHTTPHeaderFields, body: request.httpBody)
        #endif

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                #if DEBUG
                APILogger.logError(endpoint: APIEndpoint.profilePicture, error: error)
                #endif
                completion(.failure(.requestFailed(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            let statusCode = httpResponse.statusCode
            #if DEBUG
            APILogger.logResponse(endpoint: APIEndpoint.profilePicture, statusCode: statusCode, data: data ?? Data())
            #endif

            guard (200...299).contains(statusCode) else {
                completion(.failure(.serverError(statusCode: statusCode, data: data)))
                return
            }

            completion(.success(()))
        }
        .resume()
    }

    private func createMultipartBody(fieldName: String,
                                     fileName: String,
                                     mimeType: String,
                                     data: Data,
                                     boundary: String) -> Data {
        var body = Data()
        let lineBreak = "\r\n"

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\(lineBreak)")
        body.append("Content-Type: \(mimeType)\(lineBreak + lineBreak)")
        body.append(data)
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")

        return body
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

private extension String {
    var fileExtension: String {
        switch self {
        case "image/png":
            return "png"
        case "image/gif":
            return "gif"
        case "image/heic":
            return "heic"
        default:
            return "jpg"
        }
    }
}
