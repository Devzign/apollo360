//
//  APIClient.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case encodingFailed(Error)
    case requestFailed(Error)
    case invalidResponse
    case serverError(statusCode: Int, data: Data?)
    case decodingFailed(Error)
    case noData
}

private struct EmptyRequestBody: Encodable {}

final class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let baseURL: URL
    
    private init(session: URLSession = .shared,
                 baseURL: URL = APIConfiguration.baseURL) {
        self.session = session
        self.baseURL = baseURL
    }
    
    func request<Body: Encodable, T: Decodable>(endpoint: String,
                                                method: HTTPMethod = .post,
                                                body: Body? = nil,
                                                headers: [String: String]? = nil,
                                                responseType: T.Type,
                                                completion: @escaping (Result<T, APIError>) -> Void) {
        performDataRequest(endpoint: endpoint, method: method, body: body, headers: headers) { result in
            switch result {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(responseType, from: data)
                    self.completeOnMain(completion, .success(decoded))
                } catch {
                    self.completeOnMain(completion, .failure(.decodingFailed(error)))
                }
            case .failure(let error):
                self.completeOnMain(completion, .failure(error))
            }
        }
    }
    
    func request<T: Decodable>(endpoint: String,
                               method: HTTPMethod = .post,
                               headers: [String: String]? = nil,
                               responseType: T.Type,
                               completion: @escaping (Result<T, APIError>) -> Void) {
        request(endpoint: endpoint,
                method: method,
                body: Optional<EmptyRequestBody>.none,
                headers: headers,
                responseType: responseType,
                completion: completion)
    }
    
    func performDataRequest<Body: Encodable>(endpoint: String,
                                             method: HTTPMethod = .post,
                                             body: Body? = nil,
                                             headers: [String: String]? = nil,
                                             completion: @escaping (Result<Data, APIError>) -> Void) {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if method != .get {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if let headers = headers {
            headers.forEach { key, value in
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                completeOnMain(completion, .failure(.encodingFailed(error)))
                return
            }
        }

        #if DEBUG
        APILogger.logRequest(
            endpoint: endpoint,
            method: method.rawValue,
            headers: request.allHTTPHeaderFields,
            body: request.httpBody
        )
        #endif
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                #if DEBUG
                APILogger.logError(endpoint: endpoint, error: error)
                #endif
                self.completeOnMain(completion, .failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                debugPrint("[APIClient] invalid response")
                self.completeOnMain(completion, .failure(.invalidResponse))
                return
            }
            
            let statusCode = httpResponse.statusCode
            let data = data ?? Data()
            
            #if DEBUG
            APILogger.logResponse(endpoint: endpoint, statusCode: statusCode, data: data)
            #endif
            guard (200...299).contains(statusCode) else {
                if statusCode == 401 {
                    NotificationCenter.default.post(name: .sessionInvalidated, object: nil)
                }
                self.completeOnMain(completion, .failure(.serverError(statusCode: statusCode, data: data)))
                return
            }
            
            guard !data.isEmpty else {
                self.completeOnMain(completion, .failure(.noData))
                return
            }
            
            self.completeOnMain(completion, .success(data))
        }
        .resume()
    }
    
    private func completeOnMain<T>(_ completion: @escaping (Result<T, APIError>) -> Void,
                                   _ result: Result<T, APIError>) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
    
    // Convenience overload without body for simple requests
    func performDataRequest(endpoint: String,
                            method: HTTPMethod = .post,
                            headers: [String: String]? = nil,
                            completion: @escaping (Result<Data, APIError>) -> Void) {
        performDataRequest(endpoint: endpoint,
                           method: method,
                           body: Optional<EmptyRequestBody>.none,
                           headers: headers,
                           completion: completion)
    }
    
    func patientLogin(with payload: PatientLoginRequest,
                      completion: @escaping (Result<Data, APIError>) -> Void) {
        performDataRequest(endpoint: APIEndpoint.patientLogin, method: .post, body: payload, completion: completion)
    }
    
    func verifyOTP(with payload: VerifyOTPRequest,
                   completion: @escaping (Result<PatientLoginResponse, APIError>) -> Void) {
        request(endpoint: APIEndpoint.verifyOTP,
                method: .post,
                body: payload,
                responseType: PatientLoginResponse.self,
                completion: completion)
    }
    
    func loginWithPassword(with payload: PasswordLoginRequest,
                           completion: @escaping (Result<PasswordLoginResponse, APIError>) -> Void) {
        request(endpoint: APIEndpoint.passwordLogin,
                method: .post,
                body: payload,
                responseType: PasswordLoginResponse.self,
                completion: completion)
    }

    func logout(bearerToken: String,
                completion: @escaping (Result<LogoutResponse, APIError>) -> Void) {
        request(endpoint: APIEndpoint.logout,
                method: .post,
                headers: ["Authorization": "Bearer \(bearerToken)"],
                responseType: LogoutResponse.self,
                completion: completion)
    }
    
}

extension APIClient {
    fileprivate struct ServerErrorPayload: Decodable {
        let message: String?
        let errorCode: String?
    }
    
    fileprivate static func serverErrorMessage(from data: Data?) -> String? {
        guard let data, !data.isEmpty else {
            return nil
        }
        if let payload = try? JSONDecoder().decode(ServerErrorPayload.self, from: data),
           let message = payload.message?.trimmingCharacters(in: .whitespacesAndNewlines),
           !message.isEmpty {
            return message
        }
        let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return raw?.isEmpty == false ? raw : nil
    }
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .encodingFailed(let error):
            return error.localizedDescription
        case .requestFailed(let error):
            return error.localizedDescription
        case .invalidResponse:
            return "The server returned an unexpected response."
        case .serverError(let statusCode, let data):
            if let backendMessage = APIClient.serverErrorMessage(from: data) {
                return backendMessage
            }
            return HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized
        case .decodingFailed(let error):
            return "Unable to read the server response. \(error.localizedDescription)"
        case .noData:
            return "The server returned no data."
        }
    }
}
