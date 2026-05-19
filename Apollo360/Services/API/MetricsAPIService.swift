//
//  MetricsAPIService.swift
//  Apollo360
//
//  Created by Codex on 16/02/26.
//

import Foundation

enum MetricDataSource: String, Hashable {
    case rpm
    case lab
}

struct MetricFolderItem: Identifiable, Hashable {
    enum SourceSection: String {
        case careTeam
        case myMetrics
    }

    let id: String
    let title: String
    let metricField: String
    let unit: String?
    let metricType: String
    let sourceSection: SourceSection
    let dataSource: MetricDataSource
}

struct MetricCompareOption: Identifiable, Hashable {
    let id: String
    let title: String
    let metricField: String
    let category: MetricDataSource
}

struct UserMetricSeriesPayload {
    let points: [Double]
    let lastValueText: String
    let averageValueText: String
    let dateRangeText: String
}

struct MetricFullDetailPayload {
    let detailText: String?
    let lastValueText: String?
    let comparedMetricId: String?
    let comparedMetricType: MetricDataSource?
}

struct MetricCompareOptionsPayload {
    let rpm: [MetricCompareOption]
    let lab: [MetricCompareOption]

    var all: [MetricCompareOption] {
        (rpm + lab).sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}

struct RPMMetricSelectionItem: Identifiable, Hashable {
    let id: Int
    let metric: String
    let description: String
    let glossaryDisplay: String
    let isChecked: Bool
    let isDisabled: Bool
    let isAvailable: Bool
}

struct RPMMetricSelectionCategory: Identifiable, Hashable {
    let id: String
    let title: String
    let availableMetrics: [RPMMetricSelectionItem]
    let unavailableMetrics: [RPMMetricSelectionItem]
}

struct MetricFolderFilters {
    let favourites: Bool?
    let tags: [String]
    let metricIds: [String]

    init(favourites: Bool? = nil, tags: [String] = [], metricIds: [String] = []) {
        self.favourites = favourites
        self.tags = tags
        self.metricIds = metricIds
    }
}

struct BasicMetricOption: Identifiable, Hashable {
    let id: String
    let title: String
}

final class MetricsAPIService {
    static let shared = MetricsAPIService()

    private init() {}

    private struct EmptyJSONBody: Encodable {}

    func fetchRPMMetricFolders(patientId: String,
                               filters: MetricFolderFilters? = nil,
                               bearerToken: String,
                               completion: @escaping (Result<[MetricFolderItem], APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: Self.appendFilters(to: APIEndpoint.rpmFolderMetrics(for: patientId), filters: filters),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseRPMMetricFolders(from: $0)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchLabMetricFolders(patientId: String,
                               filters: MetricFolderFilters? = nil,
                               bearerToken: String,
                               completion: @escaping (Result<[MetricFolderItem], APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: Self.appendFilters(to: APIEndpoint.labFolderMetrics(for: patientId), filters: filters),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseLabMetricFolders(from: $0)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchCompareOptions(patientId: String,
                             bearerToken: String,
                             completion: @escaping (Result<MetricCompareOptionsPayload, APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.labAvailableMetricList(for: patientId),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseCompareOptions(from: $0)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchUserMetricSeries(metricField: String,
                               patientId: String,
                               selectedRange: String,
                               source: MetricDataSource,
                               bearerToken: String,
                               completion: @escaping (Result<UserMetricSeriesPayload, APIError>) -> Void) {
        let endpoint: String
        switch source {
        case .rpm:
            endpoint = APIEndpoint.userMetric(metricField: metricField, patientId: patientId, selectedRange: selectedRange)
        case .lab:
            endpoint = APIEndpoint.userLabMetric(metricField: metricField, patientId: patientId, selectedRange: selectedRange)
        }

        APIClient.shared.performDataRequest(
            endpoint: endpoint,
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseUserMetricSeries(from: $0)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchMetricDescription(metricField: String,
                                patientId: String,
                                memberId: String,
                                source: MetricDataSource,
                                bearerToken: String,
                                completion: @escaping (Result<MetricFullDetailPayload, APIError>) -> Void) {
        let endpoint: String
        switch source {
        case .rpm:
            endpoint = APIEndpoint.metricDescription(metricField: metricField, patientId: patientId, memberId: memberId)
        case .lab:
            endpoint = APIEndpoint.labMetricDetail(metricField: metricField, patientId: patientId, memberId: memberId)
        }

        APIClient.shared.performDataRequest(
            endpoint: endpoint,
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseMetricFullDetail(from: $0)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func checkMetric(metricId: String,
                     patientId: String,
                     memberId: String,
                     source: MetricDataSource,
                     bearerToken: String,
                     completion: @escaping (Result<Void, APIError>) -> Void) {
        let endpoint: String
        switch source {
        case .rpm:
            endpoint = APIEndpoint.checkUserMetric(metricId: metricId, patientId: patientId, memberId: memberId)
        case .lab:
            endpoint = APIEndpoint.checkLabMetric(metricId: metricId, patientId: patientId, memberId: memberId)
        }

        // No body — server rejects any payload on these PUT endpoints
        APIClient.shared.performDataRequest(
            endpoint: endpoint,
            method: .put,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success, .failure(.noData):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchCompareUserMetric(metricId: String,
                                compMetricId: String,
                                patientId: String,
                                memberId: String,
                                source: MetricDataSource,
                                selectedCategory: MetricDataSource,
                                bearerToken: String,
                                completion: @escaping (Result<Void, APIError>) -> Void) {
        let endpoint: String
        switch source {
        case .rpm:
            endpoint = APIEndpoint.compareUserMetric(
                metricId: metricId,
                compMetricId: compMetricId,
                patientId: patientId,
                memberId: memberId,
                metricType: selectedCategory.rawValue
            )
        case .lab:
            endpoint = APIEndpoint.compareUserLabMetric(
                metricId: metricId,
                compMetricId: compMetricId,
                patientId: patientId,
                memberId: memberId,
                metricType: selectedCategory.rawValue
            )
        }

        // No body — server rejects any payload on these PUT endpoints
        APIClient.shared.performDataRequest(
            endpoint: endpoint,
            method: .put,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success, .failure(.noData):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func saveUserMetrics(patientId: String,
                         memberId: String,
                         metricIds: [Int],
                         bearerToken: String,
                         completion: @escaping (Result<Void, APIError>) -> Void) {
        struct SaveUserMetricsRequest: Encodable {
            let metricIds: [Int]
        }

        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.saveUserMetrics(patientId: patientId, memberId: memberId),
            method: .put,
            body: SaveUserMetricsRequest(metricIds: metricIds),
            headers: [
                "Authorization": "Bearer \(bearerToken)",
                "Content-Type": "application/json"
            ]
        ) { result in
            switch result {
            case .success, .failure(.noData):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchAllRPMMetricSelections(patientId: String,
                                     bearerToken: String,
                                     completion: @escaping (Result<[RPMMetricSelectionCategory], APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.showAllRPMMetrics(for: patientId),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseRPMMetricSelections(from: $0)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchAllLabMetricSelections(patientId: String,
                                     bearerToken: String,
                                     completion: @escaping (Result<[BasicMetricOption], APIError>) -> Void) {
        let primaryEndpoint = APIEndpoint.getAvailableLabMetrics(for: patientId)
        let fallbackEndpoint = APIEndpoint.showAllLabMetrics(for: patientId)

        APIClient.shared.performDataRequest(
            endpoint: primaryEndpoint,
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseBasicMetricOptions(from: $0)
                }
            case .failure:
                APIClient.shared.performDataRequest(
                    endpoint: fallbackEndpoint,
                    method: .get,
                    headers: ["Authorization": "Bearer \(bearerToken)"]
                ) { fallbackResult in
                    switch fallbackResult {
                    case .success(let data):
                        self.decodeJSONObject(from: data, completion: completion) {
                            Self.parseBasicMetricOptions(from: $0)
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func fetchUnmanagedLabMetricCount(bearerToken: String,
                                      completion: @escaping (Result<Int, APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.manageLabMetricsData(type: "unmanaged_count"),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseUnmanagedCount(from: $0)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchLabFavouriteMetrics(bearerToken: String,
                                  completion: @escaping (Result<[BasicMetricOption], APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.labMetricsFavourite,
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseBasicMetricOptions(from: $0)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchRPMFavouriteMetrics(bearerToken: String,
                                  completion: @escaping (Result<[BasicMetricOption], APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.rpmMetricsFavourite,
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseBasicMetricOptions(from: $0)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchMetricTags(bearerToken: String,
                         completion: @escaping (Result<[String], APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.tagsList,
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                self.decodeJSONObject(from: data, completion: completion) {
                    Self.parseTagList(from: $0)
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateLabPostValue(id: Int,
                            value: String,
                            bearerToken: String,
                            completion: @escaping (Result<Void, APIError>) -> Void) {
        struct UpdateLabPostValueRequest: Encodable {
            let id: Int
            let postValue: String

            enum CodingKeys: String, CodingKey {
                case id
                case postValue = "post_value"
            }
        }

        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.updateLabPostValue,
            method: .put,
            body: UpdateLabPostValueRequest(id: id, postValue: value),
            headers: [
                "Authorization": "Bearer \(bearerToken)",
                "Content-Type": "application/json"
            ]
        ) { result in
            switch result {
            case .success, .failure(.noData):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private extension MetricsAPIService {
    static func appendFilters(to endpoint: String, filters: MetricFolderFilters?) -> String {
        guard let filters else { return endpoint }
        var queryItems: [String] = []

        if let favourites = filters.favourites {
            queryItems.append("favourites=\(favourites ? "true" : "false")")
        }

        for tag in filters.tags where !tag.isEmpty {
            let encoded = tag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tag
            queryItems.append("tags=\(encoded)")
        }

        for metricId in filters.metricIds where !metricId.isEmpty {
            let encoded = metricId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? metricId
            queryItems.append("metric_ids=\(encoded)")
        }

        guard !queryItems.isEmpty else { return endpoint }
        return "\(endpoint)?\(queryItems.joined(separator: "&"))"
    }

    func decodeJSONObject<T>(from data: Data,
                             completion: @escaping (Result<T, APIError>) -> Void,
                             transform: (Any) -> T) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            completion(.success(transform(json)))
        } catch {
            completion(.failure(.decodingFailed(error)))
        }
    }

    static func parseRPMMetricFolders(from json: Any) -> [MetricFolderItem] {
        if let dict = json as? [String: Any],
           let data = dict["data"] as? [[String: Any]],
           let first = data.first {
            let careTeam = parseMetricMap(first["careTeamMetrics"], defaultSource: .rpm, sourceSection: .careTeam)
            let mine = parseMetricMap(first["myMetrics"], defaultSource: .rpm, sourceSection: .myMetrics)
            return careTeam + mine
        }

        return extractPrimaryArray(from: json).compactMap {
            parseStandaloneFolderItem($0, defaultSource: .rpm, sourceSection: .myMetrics)
        }
    }

    static func parseLabMetricFolders(from json: Any) -> [MetricFolderItem] {
        if let dict = json as? [String: Any] {
            if let data = dict["data"] as? [[String: Any]] {
                if let first = data.first,
                   let labMetrics = first["labMetrics"] as? [String: Any] {
                    return parseMetricMap(labMetrics, defaultSource: .lab, sourceSection: .myMetrics)
                }

                return data.compactMap {
                    parseStandaloneFolderItem($0, defaultSource: .lab, sourceSection: .myMetrics)
                }
            }

            if let metrics = dict["metrics"] as? [Any] {
                return metrics.compactMap {
                    parseStandaloneFolderItem($0, defaultSource: .lab, sourceSection: .myMetrics)
                }
            }
        }

        return extractPrimaryArray(from: json).compactMap {
            parseStandaloneFolderItem($0, defaultSource: .lab, sourceSection: .myMetrics)
        }
    }

    static func parseRPMMetricSelections(from json: Any) -> [RPMMetricSelectionCategory] {
        let categories = extractPrimaryArray(from: json)
        return categories.compactMap { item in
            guard let dict = item as? [String: Any] else { return nil }
            let title = stringValue(in: dict, keys: ["category", "title", "name"]) ?? "Category"
            let available = parseRPMMetricSelectionItems(dict["availableMetrics"], isAvailable: true)
            let unavailable = parseRPMMetricSelectionItems(dict["unavailableMetrics"], isAvailable: false)

            return RPMMetricSelectionCategory(
                id: title.lowercased().replacingOccurrences(of: " ", with: "_"),
                title: title,
                availableMetrics: available,
                unavailableMetrics: unavailable
            )
        }
    }

    static func parseBasicMetricOptions(from json: Any) -> [BasicMetricOption] {
        let rootArray = extractPrimaryArray(from: json)

        var items: [BasicMetricOption] = rootArray.compactMap { item in
            guard let dict = item as? [String: Any] else { return nil }
            let id = stringValue(in: dict, keys: ["entry_id", "id", "metric_id", "main_entry_id", "metric"]) ?? UUID().uuidString
            let title = stringValue(in: dict, keys: ["description", "title", "name", "metric"]) ?? id
            return BasicMetricOption(id: id, title: title)
        }

        if items.isEmpty,
           let dict = json as? [String: Any],
           let data = dict["data"] as? [String: Any] {
            let available = (data["availableMetrics"] as? [Any]) ?? []
            let unavailable = (data["unavailableMetrics"] as? [Any]) ?? []
            let combined = available + unavailable
            items = combined.compactMap { item in
                guard let metric = item as? [String: Any] else { return nil }
                let id = stringValue(in: metric, keys: ["entry_id", "id", "metric"]) ?? UUID().uuidString
                let title = stringValue(in: metric, keys: ["description", "title", "name", "metric"]) ?? id
                return BasicMetricOption(id: id, title: title)
            }
        }

        var seen = Set<String>()
        return items.filter { seen.insert($0.id).inserted }
    }

    static func parseUnmanagedCount(from json: Any) -> Int {
        if let array = json as? [[String: Any]], let first = array.first {
            return intValue(in: first, keys: ["unmanaged_count", "count"]) ?? 0
        }

        if let dict = json as? [String: Any] {
            if let value = intValue(in: dict, keys: ["unmanaged_count", "count"]) {
                return value
            }

            if let dataArray = dict["data"] as? [[String: Any]], let first = dataArray.first {
                return intValue(in: first, keys: ["unmanaged_count", "count"]) ?? 0
            }
        }

        return 0
    }

    static func parseTagList(from json: Any) -> [String] {
        let raw = extractPrimaryArray(from: json)
        let tags = raw.compactMap { item -> String? in
            if let value = item as? String {
                return value
            }
            if let dict = item as? [String: Any] {
                return stringValue(in: dict, keys: ["tag", "name", "title", "value"])
            }
            return nil
        }
        return Array(Set(tags)).sorted()
    }

    static func parseRPMMetricSelectionItems(_ raw: Any?, isAvailable: Bool) -> [RPMMetricSelectionItem] {
        guard let array = raw as? [Any] else { return [] }
        return array.compactMap { item in
            guard let dict = item as? [String: Any] else { return nil }
            guard let entryIdText = stringValue(in: dict, keys: ["entry_id", "id"]),
                  let entryId = Int(entryIdText) else {
                return nil
            }

            let metric = stringValue(in: dict, keys: ["metric"]) ?? ""
            let description = stringValue(in: dict, keys: ["description", "title", "name"]) ?? metric
            let glossary = stringValue(in: dict, keys: ["glossary_display", "glossary", "description_text"]) ?? ""
            let checked = boolValue(in: dict, keys: ["checked"])
            let disabled = boolValue(in: dict, keys: ["disabled"])

            return RPMMetricSelectionItem(
                id: entryId,
                metric: metric,
                description: description,
                glossaryDisplay: glossary,
                isChecked: checked,
                isDisabled: disabled,
                isAvailable: isAvailable
            )
        }
    }

    static func parseCompareOptions(from json: Any) -> MetricCompareOptionsPayload {
        if let dict = json as? [String: Any] {
            if let nested = dict["data"] as? [[String: Any]] {
                let rpm = nested.flatMap { parseCompareOptionArray($0["rpm"], category: .rpm) }
                let lab = nested.flatMap { parseCompareOptionArray($0["lab"], category: .lab) }
                return MetricCompareOptionsPayload(rpm: uniqueCompareOptions(rpm), lab: uniqueCompareOptions(lab))
            }

            let rpm = parseCompareOptionArray(dict["rpm"], category: .rpm)
            let lab = parseCompareOptionArray(dict["lab"], category: .lab)
            return MetricCompareOptionsPayload(rpm: uniqueCompareOptions(rpm), lab: uniqueCompareOptions(lab))
        }

        return MetricCompareOptionsPayload(rpm: [], lab: [])
    }

    static func parseCompareOptionArray(_ raw: Any?, category: MetricDataSource) -> [MetricCompareOption] {
        guard let array = raw as? [Any] else { return [] }
        return array.compactMap { item in
            guard let dict = item as? [String: Any] else {
                if let title = item as? String, !title.isEmpty {
                    return MetricCompareOption(
                        id: title.lowercased().replacingOccurrences(of: " ", with: "_"),
                        title: title,
                        metricField: title.lowercased().replacingOccurrences(of: " ", with: "_"),
                        category: category
                    )
                }
                return nil
            }

            let id = stringValue(in: dict, keys: ["entry_id", "id", "metricId", "metric_id", "compare_metric_id"])
                ?? stringValue(in: dict, keys: ["metric_field", "current_metric_field", "field"])
            let title = stringValue(in: dict, keys: ["title", "name", "metricName", "metric_name", "label", "description"])
            let metricField = stringValue(in: dict, keys: ["metric_field", "current_metric_field", "field"])
                ?? title?.lowercased().replacingOccurrences(of: " ", with: "_")

            guard let resolvedId = id, let resolvedTitle = title, let resolvedField = metricField else {
                return nil
            }

            return MetricCompareOption(
                id: resolvedId,
                title: resolvedTitle,
                metricField: resolvedField,
                category: category
            )
        }
    }

    static func parseUserMetricSeries(from json: Any) -> UserMetricSeriesPayload {
        let series = extractSeriesRows(from: json)
        var points = series.compactMap { row -> Double? in
            guard !row.isEmpty else { return nil }
            if row.count >= 2, let last = row.last {
                return last
            }
            return row.last
        }

        if points.isEmpty {
            points = extractPrimaryArray(from: json).compactMap { item in
                if let number = item as? NSNumber {
                    return number.doubleValue
                }
                guard let dict = item as? [String: Any] else { return nil }
                return doubleValue(in: dict, keys: ["value", "metricValue", "metric_value", "reading", "score", "y", "result", "amount"])
            }
        }

        if points.isEmpty {
            points = [0]
        }

        let payloadAverage = extractAverageValue(from: json)
        let lastValue = points.last ?? 0
        let averageValue = payloadAverage ?? points.reduce(0, +) / Double(max(points.count, 1))

        return UserMetricSeriesPayload(
            points: points,
            lastValueText: formatNumber(lastValue),
            averageValueText: formatNumber(averageValue),
            dateRangeText: formatDateRange(from: series)
        )
    }

    static func parseMetricFullDetail(from json: Any) -> MetricFullDetailPayload {
        let dict = unwrapDataDictionary(from: json) ?? (json as? [String: Any]) ?? [:]
        let detailDict = dict["detail"] as? [String: Any]

        let detailParts = [
            makeRangeText(label: "Range", from: detailDict, minKey: "min_range", maxKey: "max_range"),
            makeRangeText(label: "Optimal", from: detailDict, minKey: "optimal_from", maxKey: "optimal_thru"),
            stringValue(in: detailDict ?? [:], keys: ["default_unit"]).map { "Unit: \($0)" }
        ].compactMap { $0 }

        let compared = (dict["compared"] as? [[String: Any]])?.first
        let comparedMetricId = stringValue(in: compared ?? [:], keys: ["compare_metric_id", "metric_id", "id"])
        let comparedMetricType = stringValue(in: compared ?? [:], keys: ["compare_metric_type"]).flatMap(MetricDataSource.init(rawValue:))

        let lastValue = stringValue(in: dict, keys: ["last", "lastValue", "last_value", "value", "reading"])

        return MetricFullDetailPayload(
            detailText: detailParts.isEmpty ? nil : detailParts.joined(separator: "  "),
            lastValueText: lastValue,
            comparedMetricId: comparedMetricId,
            comparedMetricType: comparedMetricType
        )
    }

    static func parseMetricMap(_ raw: Any?,
                               defaultSource: MetricDataSource,
                               sourceSection: MetricFolderItem.SourceSection) -> [MetricFolderItem] {
        guard let dict = raw as? [String: Any] else { return [] }
        return dict.compactMap { key, value in
            guard let metric = value as? [String: Any] else { return nil }
            let id = stringValue(in: metric, keys: ["current_metric_id", "metric_id", "id"]) ?? key
            let field = stringValue(in: metric, keys: ["current_metric_field", "metric_field", "field"]) ?? key
            let title = stringValue(in: metric, keys: ["current_description", "description", "title", "name"]) ?? field
            let unit = stringValue(in: metric, keys: ["current_default_unit", "unit"])
            let source = sourceValue(in: metric, keys: ["compare_metric_type", "metric_type"]) ?? defaultSource

            return MetricFolderItem(
                id: id,
                title: title,
                metricField: field,
                unit: unit,
                metricType: source.rawValue,
                sourceSection: sourceSection,
                dataSource: defaultSource
            )
        }
    }

    static func parseStandaloneFolderItem(_ raw: Any,
                                          defaultSource: MetricDataSource,
                                          sourceSection: MetricFolderItem.SourceSection) -> MetricFolderItem? {
        guard let dict = raw as? [String: Any] else { return nil }
        let id = stringValue(in: dict, keys: ["id", "metricId", "metric_id", "folderMetricId", "folder_metric_id"])
            ?? stringValue(in: dict, keys: ["title", "name", "metricName", "metric_name"])
        let metricField = stringValue(in: dict, keys: ["current_metric_field", "metric_field", "field"])
        let title = stringValue(in: dict, keys: ["title", "name", "metricName", "metric_name", "label"])
            ?? stringValue(in: dict, keys: ["current_description", "description"])
            ?? "Metric"
        guard let resolvedId = id else { return nil }

        return MetricFolderItem(
            id: resolvedId,
            title: title,
            metricField: metricField ?? title.lowercased().replacingOccurrences(of: " ", with: "_"),
            unit: stringValue(in: dict, keys: ["current_default_unit", "unit"]),
            metricType: (sourceValue(in: dict, keys: ["compare_metric_type", "metric_type"]) ?? defaultSource).rawValue,
            sourceSection: sourceSection,
            dataSource: defaultSource
        )
    }

    static func unwrapDataDictionary(from json: Any) -> [String: Any]? {
        guard let dict = json as? [String: Any] else { return nil }
        if let nested = dict["data"] as? [String: Any] {
            return nested
        }
        return dict
    }

    static func extractPrimaryArray(from json: Any) -> [Any] {
        if let array = json as? [Any] {
            return array
        }
        guard let dict = json as? [String: Any] else {
            return []
        }
        for key in ["data", "result", "results", "metrics", "list", "items", "folders"] {
            if let array = dict[key] as? [Any] {
                return array
            }
        }
        return []
    }

    static func extractSeriesRows(from json: Any) -> [[Double]] {
        let root = unwrapDataDictionary(from: json) ?? (json as? [String: Any]) ?? [:]
        for key in ["data", "chart", "chartData", "series", "points", "values"] {
            if let array = root[key] as? [Any] {
                let rows = array.compactMap { item -> [Double]? in
                    if let values = item as? [NSNumber] {
                        return values.map(\.doubleValue)
                    }
                    if let values = item as? [Double] {
                        return values
                    }
                    if let values = item as? [Any] {
                        let doubles = values.compactMap { value -> Double? in
                            if let number = value as? NSNumber { return number.doubleValue }
                            if let text = value as? String { return Double(text) }
                            return nil
                        }
                        return doubles.isEmpty ? nil : doubles
                    }
                    return nil
                }
                if !rows.isEmpty { return rows }
            }
        }
        return []
    }

    static func intValue(in dict: [String: Any], keys: [String]) -> Int? {
        for key in keys {
            if let number = dict[key] as? NSNumber {
                return number.intValue
            }
            if let text = dict[key] as? String, let value = Int(text) {
                return value
            }
        }
        return nil
    }

    static func uniqueCompareOptions(_ options: [MetricCompareOption]) -> [MetricCompareOption] {
        var seen = Set<String>()
        return options.filter { option in
            let key = "\(option.category.rawValue):\(option.id):\(option.metricField)"
            return seen.insert(key).inserted
        }
    }

    static func extractAverageValue(from json: Any) -> Double? {
        let dict = unwrapDataDictionary(from: json) ?? (json as? [String: Any]) ?? [:]
        return doubleValue(in: dict, keys: ["average", "avg", "averageValue"])
    }

    static func formatDateRange(from rows: [[Double]]) -> String {
        guard let firstTimestamp = rows.first?.first,
              let lastTimestamp = rows.last?.first,
              firstTimestamp > 10_000,
              lastTimestamp > 10_000 else {
            return "Recent Data"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy"

        let start = date(fromTimestamp: firstTimestamp)
        let end = date(fromTimestamp: lastTimestamp)
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    static func date(fromTimestamp value: Double) -> Date {
        let seconds = value > 9_999_999_999 ? value / 1000 : value
        return Date(timeIntervalSince1970: seconds)
    }

    static func makeRangeText(label: String,
                              from dict: [String: Any]?,
                              minKey: String,
                              maxKey: String) -> String? {
        guard let dict else { return nil }
        let minValue = stringValue(in: dict, keys: [minKey])
        let maxValue = stringValue(in: dict, keys: [maxKey])

        switch (minValue, maxValue) {
        case let (.some(min), .some(max)):
            return "\(label): \(min)-\(max)"
        case let (.some(min), nil):
            return "\(label): \(min)"
        case let (nil, .some(max)):
            return "\(label): \(max)"
        default:
            return nil
        }
    }

    static func stringValue(in dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dict[key] as? String, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
            if let number = dict[key] as? NSNumber {
                return number.stringValue
            }
            if let value = dict[key] as? Double {
                return formatNumber(value)
            }
            if let value = dict[key] as? Int {
                return "\(value)"
            }
        }
        return nil
    }

    static func doubleValue(in dict: [String: Any], keys: [String]) -> Double? {
        for key in keys {
            if let number = dict[key] as? NSNumber {
                return number.doubleValue
            }
            if let text = dict[key] as? String, let value = Double(text) {
                return value
            }
        }
        return nil
    }

    static func boolValue(in dict: [String: Any], keys: [String]) -> Bool {
        for key in keys {
            if let value = dict[key] as? Bool {
                return value
            }
            if let number = dict[key] as? NSNumber {
                return number.boolValue
            }
            if let text = dict[key] as? String {
                let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if ["true", "1", "yes"].contains(normalized) { return true }
                if ["false", "0", "no"].contains(normalized) { return false }
            }
        }
        return false
    }

    static func sourceValue(in dict: [String: Any], keys: [String]) -> MetricDataSource? {
        for key in keys {
            if let raw = dict[key] as? String, let source = MetricDataSource(rawValue: raw.lowercased()) {
                return source
            }
        }
        return nil
    }

    static func formatNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}
