//
//  RecordsViewModel.swift
//  Apollo360
//
//  Created by Codex on 07/04/26.
//

import Foundation
import Combine

@MainActor
final class RecordsViewModel: ObservableObject {
    enum Segment: String, CaseIterable, Identifiable {
        case documents = "Documents"
        case doctorVisits = "Doctor Visits"

        var id: String { rawValue }
    }

    @Published private(set) var folders: [PatientDocumentFolder] = []
    @Published private(set) var encounters: [DoctorVisitEncounter] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSegment: Segment = .documents

    private let session: SessionManager
    private let service: RecordsAPIService
    private var hasLoaded = false

    init(session: SessionManager, service: RecordsAPIService = .shared) {
        self.session = session
        self.service = service
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true
        loadRecords()
    }

    func refresh() {
        loadRecords()
    }

    var visibleFolderCount: Int {
        folders.count
    }

    private func loadRecords() {
        guard !isLoading else { return }
        guard let token = session.accessToken, !token.isEmpty else {
            errorMessage = "You're not signed in."
            folders = []
            encounters = []
            return
        }
        guard let patientId = session.patientId, !patientId.isEmpty else {
            errorMessage = "Patient information is unavailable."
            folders = []
            encounters = []
            return
        }

        isLoading = true
        errorMessage = nil

        service.fetchRecords(patientId: patientId, bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                let filteredFolders = response.data.documents.folders.compactMap { folder -> PatientDocumentFolder? in
                    let visible = folder.visibleDocuments
                    guard !visible.isEmpty else { return nil }
                    return PatientDocumentFolder(
                        id: folder.id,
                        name: folder.name,
                        documentCount: visible.count,
                        documents: visible
                    )
                }
                self.folders = filteredFolders
                self.encounters = response.data.documents.officeNotes.ioEncounters
                if filteredFolders.isEmpty && self.encounters.isEmpty {
                    self.errorMessage = "No records are available right now."
                }
            case .failure(let error):
                self.folders = []
                self.encounters = []
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

@MainActor
final class DoctorVisitDetailViewModel: ObservableObject {
    @Published private(set) var summary: DoctorVisitSummaryPayload?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let session: SessionManager
    private let service: RecordsAPIService
    private let encounterId: Int

    init(session: SessionManager,
         encounterId: Int,
         service: RecordsAPIService = .shared) {
        self.session = session
        self.encounterId = encounterId
        self.service = service
    }

    func load() {
        guard !isLoading else { return }
        guard let token = session.accessToken, !token.isEmpty else {
            errorMessage = "You're not signed in."
            return
        }
        guard let patientId = session.patientId, !patientId.isEmpty else {
            errorMessage = "Patient information is unavailable."
            return
        }

        isLoading = true
        errorMessage = nil

        service.fetchVisitSummary(patientId: patientId, encounterId: encounterId, bearerToken: token) { [weak self] result in
            guard let self else { return }
            self.isLoading = false
            switch result {
            case .success(let response):
                self.summary = response.data
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
