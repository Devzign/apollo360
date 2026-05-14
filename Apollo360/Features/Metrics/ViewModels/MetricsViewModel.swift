//
//  MetricsViewModel.swift
//  Apollo360
//
//  Created by Codex on 16/02/26.
//

import Foundation
import Combine

struct MetricCardDisplay: Identifiable {
    enum SourceSection {
        case careTeam
        case myMetrics
    }

    let id: String
    let metricField: String
    let metricType: String
    let unit: String?
    let sourceSection: SourceSection
    let title: String
    let detailText: String?
    let lastValue: String
    let averageValue: String
    let dateRange: String
    let points: [Double]
    let dataSource: MetricDataSource
    let comparedWith: String?
    let comparedMetricId: String?
}

@MainActor
final class MetricsViewModel: ObservableObject {
    @Published private(set) var cards: [MetricCardDisplay] = []
    @Published private(set) var compareOptions: [MetricCompareOption] = []
    @Published private(set) var rpmSelectionCategories: [RPMMetricSelectionCategory] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isSavingCompare = false
    @Published private(set) var isLoadingRPMSelections = false
    @Published private(set) var isSavingRPMSelections = false
    @Published private(set) var unmanagedLabMetricCount: Int = 0
    @Published private(set) var labMetricTags: [String] = []
    @Published private(set) var labFavouriteMetrics: [BasicMetricOption] = []
    @Published private(set) var rpmFavouriteMetrics: [BasicMetricOption] = []
    @Published private(set) var availableLabMetricSelections: [BasicMetricOption] = []
    @Published var errorMessage: String?
    @Published var compareStatusMessage: String?
    @Published var rpmSelectionErrorMessage: String?
    @Published private(set) var selectedRange: String = "365"
    @Published private(set) var activeSource: MetricDataSource = .rpm

    private let session: SessionManager
    private let service: MetricsAPIService
    private var didLoad = false
    private var loadGeneration: Int = 0
    private let enrichmentQueue = DispatchQueue(label: "com.apollo360.metrics.enrichment", qos: .userInitiated)
    private var cachedCompareOptions: [MetricCompareOption] = []

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
        loadMetrics(for: activeSource)
    }

    func setActiveSource(_ source: MetricDataSource) {
        guard activeSource != source else { return }
        activeSource = source
        load()
    }

    private func loadMetrics(for source: MetricDataSource) {
        guard let credentials = credentials else {
            errorMessage = "Missing session or patient id."
            cards = []
            return
        }

        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true
        errorMessage = nil
        compareStatusMessage = nil

        let group = DispatchGroup()
        var rpmFolders: [MetricFolderItem] = []
        var labFolders: [MetricFolderItem] = []
        var firstError: APIError?

        if source == .rpm {
            group.enter()
            service.fetchRPMMetricFolders(patientId: credentials.patientId, bearerToken: credentials.token) { result in
                defer { group.leave() }
                switch result {
                case .success(let folders):
                    rpmFolders = folders
                case .failure(let error):
                    firstError = firstError ?? error
                }
            }

            group.enter()
            service.fetchRPMFavouriteMetrics(bearerToken: credentials.token) { result in
                defer { group.leave() }
                if case .success(let favourites) = result {
                    self.rpmFavouriteMetrics = favourites
                }
            }
        } else {
            group.enter()
            service.fetchLabMetricFolders(patientId: credentials.patientId, bearerToken: credentials.token) { result in
                defer { group.leave() }
                switch result {
                case .success(let folders):
                    labFolders = folders
                case .failure(let error):
                    firstError = firstError ?? error
                }
            }

            group.enter()
            service.fetchUnmanagedLabMetricCount(bearerToken: credentials.token) { result in
                defer { group.leave() }
                if case .success(let count) = result {
                    self.unmanagedLabMetricCount = count
                }
            }

            group.enter()
            service.fetchMetricTags(bearerToken: credentials.token) { result in
                defer { group.leave() }
                if case .success(let tags) = result {
                    self.labMetricTags = tags
                }
            }

            group.enter()
            service.fetchLabFavouriteMetrics(bearerToken: credentials.token) { result in
                defer { group.leave() }
                if case .success(let favourites) = result {
                    self.labFavouriteMetrics = favourites
                }
            }

            group.enter()
            service.fetchAllLabMetricSelections(patientId: credentials.patientId, bearerToken: credentials.token) { result in
                defer { group.leave() }
                if case .success(let options) = result {
                    self.availableLabMetricSelections = options
                }
            }
        }

        if cachedCompareOptions.isEmpty {
            group.enter()
            service.fetchCompareOptions(patientId: credentials.patientId, bearerToken: credentials.token) { result in
                defer { group.leave() }
                switch result {
                case .success(let payload):
                    self.cachedCompareOptions = payload.all
                case .failure:
                    break
                }
            }
        }

        group.notify(queue: .main) {
            guard generation == self.loadGeneration else { return }
            self.compareOptions = self.cachedCompareOptions

            if let firstError, rpmFolders.isEmpty, labFolders.isEmpty {
                self.isLoading = false
                self.errorMessage = firstError.localizedDescription
                self.cards = []
                return
            }

            let mergedFolders = (rpmFolders + labFolders)
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }

            self.cards = mergedFolders.map { folder in
                MetricCardDisplay(
                    id: folder.id,
                    metricField: folder.metricField,
                    metricType: folder.metricType,
                    unit: folder.unit,
                    sourceSection: folder.sourceSection == .careTeam ? .careTeam : .myMetrics,
                    title: folder.title,
                    detailText: nil,
                    lastValue: "0",
                    averageValue: "0",
                    dateRange: "Recent Data",
                    points: [0],
                    dataSource: folder.dataSource,
                    comparedWith: nil,
                    comparedMetricId: nil
                )
            }
            self.isLoading = false
            self.errorMessage = nil

            self.enrichCards(
                folders: mergedFolders,
                patientId: credentials.patientId,
                memberId: credentials.memberId,
                token: credentials.token,
                generation: generation
            )
        }
    }

    func updateRange(_ range: String) {
        let apiRange = Self.apiRange(for: range)
        guard selectedRange != apiRange else { return }
        selectedRange = apiRange
        load()
    }

    func compareMetric(baseMetricId: String, compareMetricId: String) {
        guard let credentials = credentials else {
            compareStatusMessage = "Missing session details."
            return
        }

        guard let baseCard = cards.first(where: { $0.id == baseMetricId }) else {
            compareStatusMessage = "Unable to find selected metric."
            return
        }

        guard let compareOption = compareOptions.first(where: { $0.id == compareMetricId }) else {
            compareStatusMessage = "Unable to find compare metric."
            return
        }

        isSavingCompare = true
        compareStatusMessage = nil

        requestCompareAndSave(baseCard: baseCard,
                              compareOption: compareOption,
                              patientId: credentials.patientId,
                              memberId: credentials.memberId,
                              token: credentials.token)
    }

    func loadRPMMetricSelections() {
        guard let credentials = credentials else {
            rpmSelectionErrorMessage = "Missing session details."
            return
        }

        isLoadingRPMSelections = true
        rpmSelectionErrorMessage = nil

        service.fetchAllRPMMetricSelections(patientId: credentials.patientId, bearerToken: credentials.token) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isLoadingRPMSelections = false
                switch result {
                case .success(let categories):
                    self.rpmSelectionCategories = categories
                case .failure(let error):
                    self.rpmSelectionErrorMessage = error.localizedDescription
                }
            }
        }
    }

    func saveRPMMetricSelections(selectedMetricIds: [Int], completion: (() -> Void)? = nil) {
        guard let credentials = credentials else {
            rpmSelectionErrorMessage = "Missing session details."
            return
        }

        isSavingRPMSelections = true
        rpmSelectionErrorMessage = nil

        service.saveUserMetrics(patientId: credentials.patientId,
                                memberId: credentials.memberId,
                                metricIds: selectedMetricIds,
                                bearerToken: credentials.token) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isSavingRPMSelections = false
                switch result {
                case .success:
                    self.compareStatusMessage = "Metrics saved successfully."
                    self.loadRPMMetricSelections()
                    self.loadMetrics(for: .rpm)
                    completion?()
                case .failure(let error):
                    self.rpmSelectionErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func enrichCards(folders: [MetricFolderItem],
                             patientId: String,
                             memberId: String,
                             token: String,
                             generation: Int) {
        guard !folders.isEmpty else { return }

        let maxConcurrentRequests = 4
        let semaphore = DispatchSemaphore(value: maxConcurrentRequests)

        for folder in folders {
            enrichmentQueue.async { [weak self] in
                guard let self else { return }
                semaphore.wait()
                self.enrichCard(folder: folder,
                                patientId: patientId,
                                memberId: memberId,
                                token: token,
                                generation: generation) {
                    semaphore.signal()
                }
            }
        }
    }

    private func enrichCard(folder: MetricFolderItem,
                            patientId: String,
                            memberId: String,
                            token: String,
                            generation: Int,
                            completion: @escaping () -> Void) {
        service.fetchUserMetricSeries(metricField: folder.metricField,
                                      patientId: patientId,
                                      selectedRange: selectedRange,
                                      source: folder.dataSource,
                                      bearerToken: token) { [weak self] result in
            guard let self else {
                completion()
                return
            }

            if case .success(let payload) = result {
                DispatchQueue.main.async {
                    guard generation == self.loadGeneration else { return }
                    self.cards = self.cards.map { current in
                        guard current.id == folder.id else { return current }
                        return MetricCardDisplay(
                            id: current.id,
                            metricField: current.metricField,
                            metricType: current.metricType,
                            unit: current.unit,
                            sourceSection: current.sourceSection,
                            title: current.title,
                            detailText: current.detailText,
                            lastValue: payload.lastValueText,
                            averageValue: payload.averageValueText,
                            dateRange: payload.dateRangeText,
                            points: payload.points,
                            dataSource: current.dataSource,
                            comparedWith: current.comparedWith,
                            comparedMetricId: current.comparedMetricId
                        )
                    }
                }
            }

            self.service.fetchMetricDescription(metricField: folder.metricField,
                                                patientId: patientId,
                                                memberId: memberId,
                                                source: folder.dataSource,
                                                bearerToken: token) { [weak self] detailResult in
                defer { completion() }
                guard let self else { return }
                guard case .success(let detail) = detailResult else { return }
                DispatchQueue.main.async {
                    guard generation == self.loadGeneration else { return }
                    let compareTitle = detail.comparedMetricId.flatMap { comparedId in
                        self.compareOptions.first(where: { $0.id == comparedId })?.title
                    }

                    self.cards = self.cards.map { current in
                        guard current.id == folder.id else { return current }
                        return MetricCardDisplay(
                            id: current.id,
                            metricField: current.metricField,
                            metricType: current.metricType,
                            unit: current.unit,
                            sourceSection: current.sourceSection,
                            title: current.title,
                            detailText: detail.detailText ?? current.detailText,
                            lastValue: detail.lastValueText ?? current.lastValue,
                            averageValue: current.averageValue,
                            dateRange: current.dateRange,
                            points: current.points,
                            dataSource: current.dataSource,
                            comparedWith: compareTitle ?? current.comparedWith,
                            comparedMetricId: detail.comparedMetricId ?? current.comparedMetricId
                        )
                    }
                }
            }
        }
    }

    private func requestCompareAndSave(baseCard: MetricCardDisplay,
                                       compareOption: MetricCompareOption,
                                       patientId: String,
                                       memberId: String,
                                       token: String) {
        service.fetchCompareUserMetric(metricId: baseCard.id,
                                       compMetricId: compareOption.id,
                                       patientId: patientId,
                                       memberId: memberId,
                                       source: baseCard.dataSource,
                                       selectedCategory: compareOption.category,
                                       bearerToken: token) { [weak self] compareResult in
            guard let self else { return }
            switch compareResult {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.isSavingCompare = false
                    self.compareStatusMessage = error.localizedDescription
                }
            case .success:
                self.service.fetchUserMetricSeries(metricField: compareOption.metricField,
                                                   patientId: patientId,
                                                   selectedRange: self.selectedRange,
                                                   source: compareOption.category,
                                                   bearerToken: token) { seriesResult in
                    DispatchQueue.main.async {
                        self.isSavingCompare = false
                        switch seriesResult {
                        case .success(let payload):
                            self.applyCompareResult(baseMetricId: baseCard.id,
                                                    compareOption: compareOption,
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
                                    compareOption: MetricCompareOption,
                                    payload: UserMetricSeriesPayload) {
        cards = cards.map { card in
            guard card.id == baseMetricId else { return card }
            return MetricCardDisplay(
                id: card.id,
                metricField: card.metricField,
                metricType: card.metricType,
                unit: card.unit,
                sourceSection: card.sourceSection,
                title: card.title,
                detailText: card.detailText,
                lastValue: card.lastValue,
                averageValue: card.averageValue,
                dateRange: payload.dateRangeText,
                points: payload.points,
                dataSource: card.dataSource,
                comparedWith: compareOption.title,
                comparedMetricId: compareOption.id
            )
        }
    }

    private static func apiRange(for uiRange: String) -> String {
        switch uiRange.uppercased() {
        case "1D":
            return "1"
        case "1W":
            return "7"
        case "1M":
            return "30"
        case "3M":
            return "90"
        case "1Y":
            return "365"
        case "ALL":
            return "all"
        default:
            return "365"
        }
    }

    private var credentials: (patientId: String, memberId: String, token: String)? {
        guard let token = session.accessToken,
              let patientId = session.patientId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !patientId.isEmpty else {
            return nil
        }
        let memberId = session.a360Id?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (patientId, (memberId?.isEmpty == false ? memberId! : patientId), token)
    }
}
