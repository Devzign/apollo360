//
//  AppointmentAPIService.swift
//  Apollo360
//
//  Created by Amit Sinha on 27/01/26.
//

import Foundation

final class AppointmentAPIService {
    static let shared = AppointmentAPIService()

    private init() {}

    func fetchAppointments(bearerToken: String,
                           completion: @escaping (Result<AppointmentsAPIResponse, APIError>) -> Void) {
        APIClient.shared.request(endpoint: APIEndpoint.appointments,
                                 method: .get,
                                 headers: ["Authorization": "Bearer \(bearerToken)"],
                                 responseType: AppointmentsAPIResponse.self,
                                 completion: completion)
    }
}
