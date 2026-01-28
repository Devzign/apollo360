//
//  MessageAPIService.swift
//  Apollo360
//
//  Created by Codex on 29/01/26.
//

import Foundation

final class MessageAPIService {
    static let shared = MessageAPIService()
    private init() {}

    private func authHeaders(token: String) -> [String: String] {
        [
            "Accept": "application/json",
            "Authorization": "Bearer \(token)"
        ]
    }

    func fetchProviders(patientId: Int,
                        token: String,
                        completion: @escaping (Result<[MessageProvider], APIError>) -> Void) {
        let endpoint = "v1/list-of-providers/\(patientId)"
        APIClient.shared.request(endpoint: endpoint,
                                 method: .get,
                                 headers: authHeaders(token: token),
                                 responseType: [MessageProvider].self,
                                 completion: completion)
    }

    func fetchMessages(patientId: Int,
                       a360hId: Int,
                       providerMemberId: Int,
                       token: String,
                       completion: @escaping (Result<MessageThreadResponse, APIError>) -> Void) {
        let endpoint = "v1/messages/all/\(patientId)?a360hId=\(a360hId)&providerMemberId=\(providerMemberId)"
        APIClient.shared.request(endpoint: endpoint,
                                 method: .get,
                                 headers: authHeaders(token: token),
                                 responseType: MessageThreadResponse.self,
                                 completion: completion)
    }

    func sendMessage(patientId: Int,
                     a360hId: Int,
                     providerMemberId: Int,
                     messageType: Int,
                     message: String,
                     urgent: Int,
                     fileData: Data?,
                     fileName: String?,
                     mimeType: String?,
                     token: String,
                     completion: @escaping (Result<Void, APIError>) -> Void) {

        guard let url = URL(string: APIConfiguration.baseURL.appendingPathComponent("v1/messages").absoluteString) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body = Data()
        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        appendField(name: "patient_id", value: "\(patientId)")
        appendField(name: "a360h_id", value: "\(a360hId)")
        appendField(name: "providerMemberId", value: "\(providerMemberId)")
        appendField(name: "message_type", value: "\(messageType)")
        appendField(name: "message", value: message)
        appendField(name: "urgent", value: "\(urgent)")

        if let fileData = fileData, let fileName = fileName, let mimeType = mimeType {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"file_upload\"; filename=\"\(fileName)\"\r\n")
            body.append("Content-Type: \(mimeType)\r\n\r\n")
            body.append(fileData)
            body.append("\r\n")
        }

        body.append("--\(boundary)--\r\n")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.serverError(statusCode: httpResponse.statusCode, data: nil)))
                return
            }

            completion(.success(()))
        }.resume()
    }
}

private extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
