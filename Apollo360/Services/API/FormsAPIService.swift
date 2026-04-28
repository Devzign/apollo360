//
//  FormsAPIService.swift
//  Apollo360
//
//  Created by Amit Sinha on 27/01/26.
//

import Foundation

final class FormsAPIService {
    static let shared = FormsAPIService()

    private init() {}

    func fetchPatientForms(bearerToken: String,
                           completion: @escaping (Result<[PatientFormAPIModel], APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.patientForms,
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: PatientFormsAPIResponse.self) { result in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchSurveys(bearerToken: String,
                      completion: @escaping (Result<[SurveyListItemResponse], APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.surveys,
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: [SurveyListItemResponse].self,
                                 completion: completion)
    }

    func fetchSurveyDetails(id: Int,
                            bearerToken: String,
                            completion: @escaping (Result<SurveyDetailResponse, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.survey(id: id),
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: SurveyDetailResponse.self,
                                 completion: completion)
    }

    func saveSurveyResponse(surveyId: Int,
                            request: SurveySaveRequest,
                            bearerToken: String,
                            completion: @escaping (Result<SurveySaveResponse, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.survey(id: surveyId),
                                 method: .patch,
                                 body: request,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: SurveySaveResponse.self,
                                 completion: completion)
    }

    func fetchPatientFormDetail(id: Int,
                                bearerToken: String,
                                completion: @escaping (Result<PatientFormGroupAPIModel, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.patientForm(id: id),
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: PatientFormDetailAPIResponse.self) { result in
            switch result {
            case .success(let response):
                completion(.success(response.data))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func signPatientForm(id: Int,
                         bearerToken: String,
                         completion: @escaping (Result<PatientFormSignResponse, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.patientFormSign(id: id),
                                 method: .post,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: PatientFormSignResponse.self,
                                 completion: completion)
    }
}
