//
//  FormsViewModel.swift
//  Apollo360
//
//  Created by Amit Sinha on 27/01/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class FormsViewModel: ObservableObject {
    @Published private(set) var forms: [PatientForm] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let session: SessionManager
    private let service: FormsAPIService

    init(session: SessionManager,
         service: FormsAPIService) {
        self.session = session
        self.service = service
        loadForms()
    }

    convenience init(session: SessionManager) {
        self.init(session: session, service: .shared)
    }

    func refresh() {
        loadForms()
    }

    private func loadForms() {
        guard !isLoading else { return }
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            forms = []
            return
        }

        isLoading = true
        errorMessage = nil

        service.fetchPatientForms(bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let data):
                self.forms = data.map(Self.mapForm)
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.forms = []
            }
        }
    }

    private static func mapForm(_ model: PatientFormAPIModel) -> PatientForm {
        PatientForm(
            id: model.id,
            title: model.title,
            description: model.description?.trimmingCharacters(in: .whitespacesAndNewlines),
            signed: model.signed,
            signedDate: model.signedDate
        )
    }
}

struct PatientForm: Identifiable {
    let id: Int
    let title: String
    let description: String?
    let signed: Bool
    let signedDate: String?

    var signedStatusText: String {
        signed ? "Signed" : "Pending"
    }

    var signedStatusColor: Color {
        signed ? AppColor.green : AppColor.yellow
    }
}
