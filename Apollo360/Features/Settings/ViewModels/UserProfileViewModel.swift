//
//  UserProfileViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 03/02/26.
//

import Foundation
import Combine

@MainActor
final class UserProfileViewModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    
    @Published private(set) var profile: Profile?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let session: SessionManager
    private let service: ProfileAPIService

    init(session: SessionManager, service: ProfileAPIService = .shared) {
        self.session = session
        self.service = service
        DispatchQueue.main.async { [weak self] in
            self?.loadProfile()
        }
    }

    func loadProfile(force: Bool = false) {
        guard !isLoading else { return }
        guard force || profile == nil else { return }
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            return
        }

        isLoading = true
        errorMessage = nil

        service.fetchProfile(bearerToken: token) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let profile):
                    self.profile = profile
                case .failure(let error):
                    self.errorMessage = Self.prettyMessage(for: error)
                }
            }
        }
    }

    var displayName: String {
        profile?.displayName ?? ""
    }

    var displayDOB: String {
        profile?.dateOfBirth ?? ""
    }

    var displayEmail: String {
        profile?.email ?? ""
    }

    var displayPhone: String {
        profile?.phone ?? ""
    }

    private static func prettyMessage(for error: APIError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid URL."
        case .encodingFailed(let err), .decodingFailed(let err):
            return "Parsing failed: \(err.localizedDescription)"
        case .requestFailed(let err):
            return err.localizedDescription
        case .invalidResponse:
            return "Invalid server response."
        case .serverError(let code, _):
            return "Server error (\(code)). Please try again."
        case .noData:
            return "No data received."
        }
    }
}
