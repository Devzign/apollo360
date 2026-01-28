//
//  AppointmentViewModel.swift
//  Apollo360
//
//  Created by Codex on 27/01/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppointmentViewModel: ObservableObject {
    @Published private(set) var appointments: [AppointmentCard] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let session: SessionManager
    private let service: AppointmentAPIService

    init(session: SessionManager, service: AppointmentAPIService) {
        self.session = session
        self.service = service
        loadAppointments()
    }

    convenience init(session: SessionManager) {
        self.init(session: session, service: .shared)
    }

    func refresh() {
        loadAppointments()
    }

    private func loadAppointments() {
        guard !isLoading else { return }
        guard let token = session.accessToken else {
            errorMessage = "You're not signed in."
            appointments = []
            return
        }

        isLoading = true
        errorMessage = nil

        service.fetchAppointments(bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.appointments = response.appointments.map(Self.card(from:))
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.appointments = []
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = .current
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }()

    private static func card(from apiModel: AppointmentAPIModel) -> AppointmentCard {
        let dateText: String
        if let date = apiModel.date {
            dateText = dateFormatter.string(from: date)
        } else {
            dateText = "Date TBD"
        }

        let timeText: String
        if let display = apiModel.displayTime, !display.isEmpty {
            timeText = display
        } else if let date = apiModel.date {
            timeText = timeFormatter.string(from: date)
        } else {
            timeText = "--"
        }

        let accent: Color
        if apiModel.callType?.lowercased().contains("video") == true {
            accent = AppColor.blue.opacity(0.15)
        } else if apiModel.isTelevisit {
            accent = AppColor.green.opacity(0.15)
        } else {
            accent = AppColor.yellow.opacity(0.15)
        }

        return AppointmentCard(
            id: UUID(),
            name: apiModel.provider,
            role: apiModel.role ?? "Care Team",
            date: dateText,
            time: timeText,
            accentColor: accent,
            callType: apiModel.callType,
            isTelevisit: apiModel.isTelevisit
        )
    }
}

