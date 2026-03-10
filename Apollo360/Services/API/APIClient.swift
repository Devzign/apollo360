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
private struct RefreshTokenResponse: Decodable {
    let accessToken: String
    let expiresIn: Int?
    let refreshToken: String?
}

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
                                                timeoutInterval: TimeInterval? = nil,
                                                responseType: T.Type,
                                                completion: @escaping (Result<T, APIError>) -> Void) {
        performDataRequest(endpoint: endpoint,
                           method: method,
                           body: body,
                           headers: headers,
                           timeoutInterval: timeoutInterval) { result in
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
                               timeoutInterval: TimeInterval? = nil,
                               responseType: T.Type,
                               completion: @escaping (Result<T, APIError>) -> Void) {
        request(endpoint: endpoint,
                method: method,
                body: Optional<EmptyRequestBody>.none,
                headers: headers,
                timeoutInterval: timeoutInterval,
                responseType: responseType,
                completion: completion)
    }
    
    func performDataRequest<Body: Encodable>(endpoint: String,
                                             method: HTTPMethod = .post,
                                             body: Body? = nil,
                                             headers: [String: String]? = nil,
                                             timeoutInterval: TimeInterval? = nil,
                                             completion: @escaping (Result<Data, APIError>) -> Void) {
        guard let url = buildURL(from: endpoint) else {
            completeOnMain(completion, .failure(.invalidURL))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if let timeoutInterval {
            request.timeoutInterval = timeoutInterval
        }
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

        executeDataRequest(request: request, endpoint: endpoint, canRetryAfterRefresh: true, completion: completion)
    }

    private func executeDataRequest(request: URLRequest,
                                    endpoint: String,
                                    canRetryAfterRefresh: Bool,
                                    completion: @escaping (Result<Data, APIError>) -> Void) {
        if canRetryAfterRefresh,
           endpoint != APIEndpoint.refreshToken,
           let authorization = request.value(forHTTPHeaderField: "Authorization"),
           let token = Self.bearerToken(from: authorization),
           Self.isTokenNearExpiry(token) {
            refreshAccessToken { result in
                switch result {
                case .success(let refreshed):
                    var retried = request
                    retried.setValue("Bearer \(refreshed.accessToken)", forHTTPHeaderField: "Authorization")
                    self.executeDataRequest(
                        request: retried,
                        endpoint: endpoint,
                        canRetryAfterRefresh: true,
                        completion: completion
                    )
                case .failure:
                    NotificationCenter.default.post(name: .sessionInvalidated, object: nil)
                    self.completeOnMain(completion, .failure(.invalidResponse))
                }
            }
            return
        }

        #if DEBUG
        APILogger.logRequest(
            endpoint: endpoint,
            method: request.httpMethod ?? "GET",
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
                if statusCode == 401,
                   canRetryAfterRefresh,
                   request.value(forHTTPHeaderField: "Authorization") != nil,
                   endpoint != APIEndpoint.refreshToken {
                    self.refreshAccessToken { result in
                        switch result {
                        case .success(let refreshed):
                            var retried = request
                            retried.setValue("Bearer \(refreshed.accessToken)", forHTTPHeaderField: "Authorization")
                            self.executeDataRequest(
                                request: retried,
                                endpoint: endpoint,
                                canRetryAfterRefresh: false,
                                completion: completion
                            )
                        case .failure:
                            NotificationCenter.default.post(name: .sessionInvalidated, object: nil)
                            self.completeOnMain(completion, .failure(.serverError(statusCode: statusCode, data: data)))
                        }
                    }
                    return
                } else if statusCode == 401 {
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

    private func refreshAccessToken(completion: @escaping (Result<RefreshTokenResponse, APIError>) -> Void) {
        guard let refreshToken = UserDefaults.standard.string(forKey: "Apollo360.refreshToken"),
              !refreshToken.isEmpty else {
            completion(.failure(.invalidResponse))
            return
        }
        guard let url = buildURL(from: APIEndpoint.refreshToken) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(refreshToken, forHTTPHeaderField: "x-refresh-token")
        request.httpBody = Data("{}".utf8)

        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(.requestFailed(error)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            guard (200...299).contains(httpResponse.statusCode), let data, !data.isEmpty else {
                completion(.failure(.serverError(statusCode: httpResponse.statusCode, data: data)))
                return
            }

            do {
                let payload = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
                var userInfo: [AnyHashable: Any] = ["accessToken": payload.accessToken]
                if let newRefreshToken = payload.refreshToken, !newRefreshToken.isEmpty {
                    userInfo["refreshToken"] = newRefreshToken
                    UserDefaults.standard.set(newRefreshToken, forKey: "Apollo360.refreshToken")
                }
                UserDefaults.standard.set(payload.accessToken, forKey: "Apollo360.accessToken")
                NotificationCenter.default.post(name: .sessionTokensRefreshed, object: nil, userInfo: userInfo)
                completion(.success(payload))
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }
        .resume()
    }

    private static func bearerToken(from header: String) -> String? {
        let prefix = "Bearer "
        guard header.hasPrefix(prefix) else { return nil }
        let token = String(header.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        return token.isEmpty ? nil : token
    }

    private static func isTokenNearExpiry(_ jwt: String, thresholdSeconds: TimeInterval = 60) -> Bool {
        let parts = jwt.split(separator: ".")
        guard parts.count > 1 else { return false }
        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = payload.count % 4
        if remainder > 0 {
            payload += String(repeating: "=", count: 4 - remainder)
        }
        guard let data = Data(base64Encoded: payload),
              let object = try? JSONSerialization.jsonObject(with: data, options: []),
              let dict = object as? [String: Any] else {
            return false
        }
        guard let exp = dict["exp"] as? TimeInterval else { return false }
        let expiresAt = Date(timeIntervalSince1970: exp)
        return expiresAt.timeIntervalSinceNow <= thresholdSeconds
    }

    private func buildURL(from endpoint: String) -> URL? {
        guard !endpoint.isEmpty else { return nil }

        let fragments = endpoint.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        var pathPart = String(fragments[0])
        if pathPart.hasPrefix("/") {
            pathPart.removeFirst()
        }

        if fragments.count == 1 {
            return baseURL.appendingPathComponent(pathPart)
        }

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        var normalizedBasePath = components.path
        if normalizedBasePath.hasSuffix("/") {
            normalizedBasePath.removeLast()
        }
        components.path = normalizedBasePath + "/" + pathPart
        components.percentEncodedQuery = String(fragments[1])
        return components.url
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
                            timeoutInterval: TimeInterval? = nil,
                            completion: @escaping (Result<Data, APIError>) -> Void) {
        performDataRequest(endpoint: endpoint,
                           method: method,
                           body: Optional<EmptyRequestBody>.none,
                           headers: headers,
                           timeoutInterval: timeoutInterval,
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

    func updatePatientFaceID(with payload: PatientFaceIDRequest,
                             completion: @escaping (Result<PatientFaceIDResponse, APIError>) -> Void) {
        performDataRequest(endpoint: APIEndpoint.patientFaceID,
                           method: .post,
                           body: payload) { result in
            switch result {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(PatientFaceIDResponse.self, from: data)
                    self.completeOnMain(completion, .success(decoded))
                } catch {
                    self.completeOnMain(completion, .failure(.decodingFailed(error)))
                }
            case .failure(.noData):
                self.completeOnMain(completion, .success(PatientFaceIDResponse(message: nil)))
            case .failure(let error):
                self.completeOnMain(completion, .failure(error))
            }
        }
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
            return sanitizeServerMessage(message)
        }
        let raw = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let raw, !raw.isEmpty else { return nil }
        return sanitizeServerMessage(raw)
    }

    fileprivate static func sanitizeServerMessage(_ message: String) -> String? {
        let cleaned = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        if isLikelyHTML(cleaned) {
            return nil
        }
        if cleaned.count > 180 {
            return nil
        }
        return cleaned
    }

    fileprivate static func isLikelyHTML(_ text: String) -> Bool {
        let lower = text.lowercased()
        return lower.contains("<html") || lower.contains("<head") || lower.contains("<body") || lower.contains("</")
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
            if statusCode == 502 || statusCode == 503 || statusCode == 504 {
                return "Server is temporarily unavailable. Please try again."
            }
            if statusCode >= 500 {
                return "Something went wrong on server. Please try again."
            }
            return HTTPURLResponse.localizedString(forStatusCode: statusCode).capitalized
        case .decodingFailed(let error):
            return "Unable to read the server response. \(error.localizedDescription)"
        case .noData:
            return "The server returned no data."
        }
    }
}
