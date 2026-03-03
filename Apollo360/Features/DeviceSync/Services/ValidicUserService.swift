import Foundation

protocol ValidicUserServicing {
    func fetchUserProfile(configuration: DeviceSyncConfiguration, uid: String) async throws -> ValidicUserProfile
}

final class ValidicUserService: ValidicUserServicing {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUserProfile(configuration: DeviceSyncConfiguration, uid: String) async throws -> ValidicUserProfile {
        guard configuration.isReadyForProfileFetch else {
            throw DeviceSyncError.invalidConfiguration(
                "Missing Validic configuration. Set VALIDIC_URL_V2, VALIDIC_ORGANIZATION_ID and VALIDIC_TOKEN."
            )
        }

        let base = configuration.validicBaseURLV2.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let endpoint = "\(base)/organizations/\(configuration.organizationID)/users/\(uid)"
        guard var components = URLComponents(string: endpoint) else {
            throw DeviceSyncError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "token", value: configuration.validicToken)
        ]

        guard let url = components.url else {
            throw DeviceSyncError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw DeviceSyncError.invalidResponse
        }

        do {
            return try JSONDecoder.validicDecoder.decode(ValidicUserProfile.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}
