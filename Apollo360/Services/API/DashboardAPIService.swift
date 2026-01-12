import Foundation

final class DashboardAPIService {
    static let shared = DashboardAPIService()

    private init() {}

    func fetchDashboardInsights(patientId: String,
                                bearerToken: String,
                                completion: @escaping (Result<[DashboardInsightPayload], APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.dashboardInsights(for: patientId),
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: DashboardInsightsResponse.self) { result in
            switch result {
            case .success(let response):
                if response.success {
                    completion(.success(response.data))
                } else {
                    completion(.failure(.serverError(statusCode: 500, data: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchWellnessOverview(patientId: String,
                                bearerToken: String,
                                mode: WellnessMode,
                                completion: @escaping (Result<WellnessOverviewPayload, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.wellnessOverview(for: patientId, mode: mode),
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: WellnessOverviewAPIResponse.self) { result in
            switch result {
            case .success(let response):
                if response.success {
                    completion(.success(response.data))
                } else {
                    completion(.failure(.serverError(statusCode: 500, data: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchApolloInsights(patientId: String,
                             bearerToken: String,
                             completion: @escaping (Result<ApolloInsightsPayload, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.apolloInsights(for: patientId),
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: ApolloInsightsAPIResponse.self) { result in
            switch result {
            case .success(let response):
                if response.success {
                    completion(.success(response.data))
                } else {
                    completion(.failure(.serverError(statusCode: 500, data: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchCardiometabolicMetrics(patientId: String,
                                     bearerToken: String,
                                     completion: @escaping (Result<CardiometabolicMetricsPayload, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.cardiometabolicMetrics(for: patientId),
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: CardiometabolicMetricsAPIResponse.self) { result in
            switch result {
            case .success(let response):
                if response.success {
                    completion(.success(response.data))
                } else {
                    completion(.failure(.serverError(statusCode: 500, data: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchActivities(patientId: String,
                         bearerToken: String,
                         completion: @escaping (Result<ActivitiesPayload, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.activities(for: patientId),
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: ActivitiesAPIResponse.self) { result in
            switch result {
            case .success(let response):
                if response.success {
                    completion(.success(response.data))
                } else {
                    completion(.failure(.serverError(statusCode: 500, data: nil)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
