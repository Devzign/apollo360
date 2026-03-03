//
//  MetricsViewModel.swift
//  Apollo360
//
//  Created by Codex on 16/02/26.
//

import Foundation
import Combine

struct MetricCardDisplay: Identifiable {
    let id: String
    let title: String
    let detailText: String?
    let lastValue: String
    let averageValue: String
    let dateRange: String
    let points: [Double]
    let isLabAvailable: Bool
    let comparedWith: String?
}

@MainActor
final class MetricsViewModel: ObservableObject {
    @Published private(set) var cards: [MetricCardDisplay] = []
    @Published private(set) var compareOptions: [MetricFolderItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSavingCompare = false
    @Published var errorMessage: String?
    @Published var compareStatusMessage: String?

    private let session: SessionManager
    private let service: MetricsAPIService
    private var didLoad = false

    init(session: SessionManager,
         service: MetricsAPIService) {
        self.session = session
        self.service = service
    }

    @MainActor
    convenience init(session: SessionManager) {
        self.init(session: session, service: .shared)
    }

    func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        load()
    }

    func load() {
        guard let credentials = credentials else {
            errorMessage = "Missing session or patient id."
            cards = []
            return
        }

        isLoading = true
        errorMessage = nil
        compareStatusMessage = nil

        service.fetchMetricFolders(patientId: credentials.patientId, bearerToken: credentials.token) { [weak self] folderResult in
            guard let self else { return }
            switch folderResult {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.cards = []
                }
            case .success(let folders):
                self.loadLabAndSeries(patientId: credentials.patientId, token: credentials.token, folders: folders)
                self.loadCompareOptions(patientId: credentials.patientId, token: credentials.token)
            }
        }
    }

    func compareMetric(baseMetricId: String, compareMetricId: String) {
        guard let credentials = credentials else {
            compareStatusMessage = "Missing session details."
            return
        }

        isSavingCompare = true
        compareStatusMessage = nil

        service.checkMetric(patientId: credentials.patientId,
                            metricId: baseMetricId,
                            compareMetricId: compareMetricId,
                            bearerToken: credentials.token) { [weak self] checkResult in
            guard let self else { return }
            switch checkResult {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isSavingCompare = false
                    self.compareStatusMessage = error.localizedDescription
                }
            case .success:
                self.requestCompareAndSave(baseMetricId: baseMetricId,
                                           compareMetricId: compareMetricId,
                                           patientId: credentials.patientId,
                                           token: credentials.token)
            }
        }
    }

    private func loadLabAndSeries(patientId: String,
                                  token: String,
                                  folders: [MetricFolderItem]) {
        service.fetchLabAvailableMetrics(patientId: patientId, bearerToken: token) { [weak self] labResult in
            guard let self else { return }
            let refs = (try? labResult.get()) ?? []
            let labIds = Set(refs.compactMap { $0.id?.lowercased() })
            let labNames = Set(refs.compactMap { $0.title?.lowercased() })

            if folders.isEmpty {
                DispatchQueue.main.async {
                    self.cards = []
                    self.isLoading = false
                    self.errorMessage = nil
                }
                return
            }

            let group = DispatchGroup()
            var builtCards: [MetricCardDisplay] = []
            var firstError: APIError?
            let lock = NSLock()

            for folder in folders {
                group.enter()
                self.service.fetchUserMetricSeries(metricId: folder.id, patientId: patientId, bearerToken: token) { result in
                    defer { group.leave() }
                    lock.lock()
                    defer { lock.unlock() }
                    switch result {
                    case .success(let payload):
                        let isLab = labIds.contains(folder.id.lowercased()) || labNames.contains(folder.title.lowercased())
                        builtCards.append(
                            MetricCardDisplay(
                                id: folder.id,
                                title: folder.title,
                                detailText: nil,
                                lastValue: payload.lastValueText,
                                averageValue: payload.averageValueText,
                                dateRange: payload.dateRangeText,
                                points: payload.points,
                                isLabAvailable: isLab,
                                comparedWith: nil
                            )
                        )
                    case .failure(let error):
                        if firstError == nil {
                            firstError = error
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                self.cards = builtCards.sorted { $0.title < $1.title }
                self.isLoading = false
                self.errorMessage = firstError?.localizedDescription
                self.enrichMetricDetails(patientId: patientId)
            }
        }
    }

    private func loadCompareOptions(patientId: String, token: String) {
        service.fetchAllRPMMetrics(patientId: patientId, bearerToken: token) { [weak self] rpmResult in
            guard let self else { return }
            switch rpmResult {
            case .success(let rpmMetrics):
                DispatchQueue.main.async {
                    self.compareOptions = rpmMetrics.sorted { $0.title < $1.title }
                }
            case .failure:
                break
            }
        }
    }

    private func requestCompareAndSave(baseMetricId: String,
                                       compareMetricId: String,
                                       patientId: String,
                                       token: String) {
        service.fetchCompareUserMetric(patientId: patientId,
                                       primaryMetricId: baseMetricId,
                                       secondaryMetricId: compareMetricId,
                                       tertiaryMetricId: compareMetricId,
                                       compareMode: "compare",
                                       bearerToken: token) { [weak self] compareResult in
            guard let self else { return }
            switch compareResult {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isSavingCompare = false
                    self.compareStatusMessage = error.localizedDescription
                }
            case .success(let payload):
                let metricIds = [Int(baseMetricId), Int(compareMetricId)].compactMap { $0 }
                self.service.saveUserMetrics(patientId: patientId,
                                             metricGroupId: patientId,
                                             metricIds: metricIds) { saveResult in
                    DispatchQueue.main.async {
                        self.isSavingCompare = false
                        switch saveResult {
                        case .success:
                            self.applyCompareResult(baseMetricId: baseMetricId,
                                                    compareMetricId: compareMetricId,
                                                    payload: payload)
                            self.compareStatusMessage = "Comparison saved successfully."
                        case .failure(let error):
                            self.compareStatusMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    private func applyCompareResult(baseMetricId: String,
                                    compareMetricId: String,
                                    payload: CompareMetricPayload) {
        let compareTitle = compareOptions.first(where: { $0.id == compareMetricId })?.title
        cards = cards.map { card in
            guard card.id == baseMetricId else { return card }
            return MetricCardDisplay(
                id: card.id,
                title: card.title,
                detailText: card.detailText,
                lastValue: payload.lastValueText,
                averageValue: payload.averageValueText,
                dateRange: card.dateRange,
                points: payload.points,
                isLabAvailable: card.isLabAvailable,
                comparedWith: compareTitle
            )
        }
    }

    private func enrichMetricDetails(patientId: String) {
        for card in cards {
            service.fetchMetricDescription(metricId: card.id, patientId: patientId, range: "all") { [weak self] result in
                guard let self else { return }
                guard case .success(let detail) = result else { return }
                DispatchQueue.main.async {
                    self.cards = self.cards.map { current in
                        guard current.id == card.id else { return current }
                        return MetricCardDisplay(
                            id: current.id,
                            title: current.title,
                            detailText: detail.detailText ?? current.detailText,
                            lastValue: detail.lastValueText ?? current.lastValue,
                            averageValue: current.averageValue,
                            dateRange: current.dateRange,
                            points: current.points,
                            isLabAvailable: current.isLabAvailable,
                            comparedWith: current.comparedWith
                        )
                    }
                }
            }
        }
    }

    private var credentials: (patientId: String, token: String)? {
        guard let token = session.accessToken,
              let patientId = session.patientId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !patientId.isEmpty else {
            return nil
        }
        return (patientId, token)
    }
}
