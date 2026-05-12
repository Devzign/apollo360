//
//  DashboardAPIService.swift
//  Apollo360
//
//  Created by Amit Sinha on 09/01/26.
//

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
                                 timeoutInterval: 12,
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

    func fetchDashboardMetrics(patientId: String,
                               bearerToken: String,
                               selectionType: DashboardMetricSelectionType,
                               completion: @escaping (Result<DashboardMetricsPayload, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.dashboardMetrics(for: patientId, selectionType: selectionType),
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: DashboardMetricsAPIResponse.self) { result in
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

    func fetchHomeSummary(bearerToken: String,
                          completion: @escaping (Result<DashboardSummaryPayload, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.dashboardSummary,
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: DashboardSummaryAPIResponse.self) { result in
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

    func fetchHomeActivityPlans(bearerToken: String,
                                completion: @escaping (Result<DashboardActivityPlansPayload, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.dashboardActivityPlans,
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: DashboardActivityPlansAPIResponse.self) { result in
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

    func fetchHomeMetricsLookup(bearerToken: String,
                                completion: @escaping (Result<[DashboardLookupCategory], APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.dashboardMetricsLookup,
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: DashboardMetricsLookupAPIResponse.self) { result in
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
