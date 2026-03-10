//
//  MetricsAPIService.swift
//  Apollo360
//
//  Created by Codex on 16/02/26.
//

import Foundation

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
}

struct UserMetricSeriesPayload {
    let points: [Double]
    let lastValueText: String
    let averageValueText: String
    let dateRangeText: String
}

struct LabAvailableMetricReference: Hashable {
    let id: String?
    let title: String?
}

struct MetricFullDetailPayload {
    let detailText: String?
    let lastValueText: String?
}

struct CompareMetricPayload {
    let points: [Double]
    let lastValueText: String
    let averageValueText: String
}

final class MetricsAPIService {
    static let shared = MetricsAPIService()

    private init() {}

    func fetchMetricFolders(patientId: String,
                            bearerToken: String,
                            completion: @escaping (Result<[MetricFolderItem], APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.rpmFolderMetrics(for: patientId),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    let folders = Self.parseMetricFolders(from: json)
                    completion(.success(folders))
                } catch {
                    completion(.failure(.decodingFailed(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchUserMetricSeries(metricField: String,
                               patientId: String,
                               selectedRange: String,
                               bearerToken: String,
                               completion: @escaping (Result<UserMetricSeriesPayload, APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.userMetric(metricField: metricField, patientId: patientId, selectedRange: selectedRange),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    let payload = Self.parseUserMetricSeries(from: json)
                    completion(.success(payload))
                } catch {
                    completion(.failure(.decodingFailed(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchLabAvailableMetrics(patientId: String,
                                  bearerToken: String,
                                  completion: @escaping (Result<[LabAvailableMetricReference], APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.labAvailableMetricList(for: patientId),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    completion(.success(Self.parseLabAvailableMetrics(from: json)))
                } catch {
                    completion(.failure(.decodingFailed(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchAllRPMMetrics(patientId: String,
                            bearerToken: String,
                            completion: @escaping (Result<[MetricFolderItem], APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.showAllRPMMetrics(for: patientId),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    completion(.success(Self.parseMetricFolders(from: json)))
                } catch {
                    completion(.failure(.decodingFailed(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchMetricDescription(metricField: String,
                                patientId: String,
                                memberId: String,
                                bearerToken: String,
                                completion: @escaping (Result<MetricFullDetailPayload, APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.metricDescription(metricField: metricField, patientId: patientId, memberId: memberId),
            method: .get,
            headers: ["Authorization": "Bearer \(bearerToken)"]
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    completion(.success(Self.parseMetricFullDetail(from: json)))
                } catch {
                    completion(.failure(.decodingFailed(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func checkMetric(metricId: String,
                     patientId: String,
                     memberId: String,
                     bearerToken: String,
                     completion: @escaping (Result<Void, APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.checkMetric(metricId: metricId, patientId: patientId, memberId: memberId),
            method: .put,
            headers: [
                "Authorization": "Bearer \(bearerToken)",
                "Content-Type": "application/json"
            ]
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(.noData):
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
                                metricType: String,
                                bearerToken: String,
                                completion: @escaping (Result<CompareMetricPayload, APIError>) -> Void) {
        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.compareUserMetric(
                metricId: metricId,
                compMetricId: compMetricId,
                patientId: patientId,
                memberId: memberId,
                metricType: metricType
            ),
            method: .put,
            headers: [
                "Authorization": "Bearer \(bearerToken)",
                "Content-Type": "application/json"
            ]
        ) { result in
            switch result {
            case .success(let data):
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    completion(.success(Self.parseCompareMetric(from: json)))
                } catch {
                    completion(.failure(.decodingFailed(error)))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func saveUserMetrics(patientId: String,
                         metricGroupId: String,
                         metricIds: [Int],
                         completion: @escaping (Result<Void, APIError>) -> Void) {
        struct SaveUserMetricsRequest: Encodable {
            let metricIds: [Int]
        }

        APIClient.shared.performDataRequest(
            endpoint: APIEndpoint.saveUserMetrics(patientId: patientId, metricGroupId: metricGroupId),
            method: .put,
            body: SaveUserMetricsRequest(metricIds: metricIds),
            headers: ["Content-Type": "application/json"]
        ) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(.noData):
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

private extension MetricsAPIService {
    static func parseMetricFolders(from json: Any) -> [MetricFolderItem] {
        if let dict = json as? [String: Any],
           let data = dict["data"] as? [[String: Any]],
           let first = data.first {
            let careTeam = parseMetricMap(first["careTeamMetrics"], metricType: "rpm", sourceSection: .careTeam)
            let mine = parseMetricMap(first["myMetrics"], metricType: "rpm", sourceSection: .myMetrics)
            if !careTeam.isEmpty || !mine.isEmpty {
                return (careTeam + mine)
            }
        }

        let array = extractPrimaryArray(from: json)
        return array.compactMap { item in
            guard let dict = item as? [String: Any] else { return nil }
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
                metricType: stringValue(in: dict, keys: ["compare_metric_type", "metric_type"]) ?? "rpm",
                sourceSection: .myMetrics
            )
        }
    }

    static func parseUserMetricSeries(from json: Any) -> UserMetricSeriesPayload {
        let entries = extractPrimaryArray(from: json)
        var points: [Double] = entries.compactMap { item in
            if let number = item as? NSNumber {
                return number.doubleValue
            }
            guard let dict = item as? [String: Any] else { return nil }
            return doubleValue(in: dict, keys: [
                "value", "metricValue", "metric_value", "reading", "score", "y", "result", "amount"
            ])
        }

        if points.isEmpty, let dict = json as? [String: Any] {
            let candidateArrays = ["chart", "chartData", "series", "points", "values", "data"]
            for key in candidateArrays {
                if let raw = dict[key], let nested = raw as? [Any] {
                    points = nested.compactMap { item in
                        if let number = item as? NSNumber {
                            return number.doubleValue
                        }
                        guard let sub = item as? [String: Any] else { return nil }
                        return doubleValue(in: sub, keys: ["value", "y", "metricValue", "metric_value"])
                    }
                    if !points.isEmpty { break }
                }
            }
        }

        if points.isEmpty {
            points = [0, 0, 0]
        }

        let last = points.last ?? 0
        let average = points.reduce(0, +) / Double(max(points.count, 1))

        let lastText = formatNumber(last)
        let avgText = formatNumber(average)

        return UserMetricSeriesPayload(
            points: points,
            lastValueText: lastText,
            averageValueText: avgText,
            dateRangeText: "Recent Data"
        )
    }

    static func parseLabAvailableMetrics(from json: Any) -> [LabAvailableMetricReference] {
        let array = extractPrimaryArray(from: json)
        return array.compactMap { item in
            if let dict = item as? [String: Any] {
                let id = stringValue(in: dict, keys: ["id", "metricId", "metric_id"])
                let title = stringValue(in: dict, keys: ["title", "name", "metricName", "metric_name", "label"])
                return LabAvailableMetricReference(id: id, title: title)
            }
            if let text = item as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return LabAvailableMetricReference(id: nil, title: text)
            }
            return nil
        }
    }

    static func parseMetricFullDetail(from json: Any) -> MetricFullDetailPayload {
        if let dict = json as? [String: Any] {
            let detail = stringValue(in: dict, keys: ["description", "detail", "summary", "message"])
            let lastValue = stringValue(in: dict, keys: ["lastValue", "last_value", "value", "reading"])
            if detail != nil || lastValue != nil {
                return MetricFullDetailPayload(detailText: detail, lastValueText: lastValue)
            }
            if let nested = dict["data"] as? [String: Any] {
                let nestedDetail = stringValue(in: nested, keys: ["description", "detail", "summary", "message"])
                let nestedLast = stringValue(in: nested, keys: ["lastValue", "last_value", "value", "reading"])
                return MetricFullDetailPayload(detailText: nestedDetail, lastValueText: nestedLast)
            }
        }
        return MetricFullDetailPayload(detailText: nil, lastValueText: nil)
    }

    static func parseCompareMetric(from json: Any) -> CompareMetricPayload {
        let base = parseUserMetricSeries(from: json)
        if let dict = json as? [String: Any] {
            let lastValue = stringValue(in: dict, keys: ["lastValue", "last_value"]) ?? base.lastValueText
            let averageValue = stringValue(in: dict, keys: ["average", "averageValue", "avg"]) ?? base.averageValueText
            return CompareMetricPayload(points: base.points, lastValueText: lastValue, averageValueText: averageValue)
        }
        return CompareMetricPayload(points: base.points, lastValueText: base.lastValueText, averageValueText: base.averageValueText)
    }

    static func parseMetricMap(_ raw: Any?, metricType: String, sourceSection: MetricFolderItem.SourceSection) -> [MetricFolderItem] {
        guard let dict = raw as? [String: Any] else { return [] }
        return dict.compactMap { key, value in
            guard let metric = value as? [String: Any] else { return nil }
            let id = stringValue(in: metric, keys: ["current_metric_id", "metric_id", "id"]) ?? key
            let field = stringValue(in: metric, keys: ["current_metric_field", "metric_field"]) ?? key
            let title = stringValue(in: metric, keys: ["current_description", "description", "title"]) ?? field
            let unit = stringValue(in: metric, keys: ["current_default_unit", "unit"])
            let compareType = (metric["compare_metric"] as? [String: Any]).flatMap {
                stringValue(in: $0, keys: ["compare_metric_type"])
            } ?? metricType

            return MetricFolderItem(
                id: id,
                title: title,
                metricField: field,
                unit: unit,
                metricType: compareType,
                sourceSection: sourceSection
            )
        }
    }

    static func extractPrimaryArray(from json: Any) -> [Any] {
        if let array = json as? [Any] {
            return array
        }
        guard let dict = json as? [String: Any] else {
            return []
        }
        let keys = ["data", "result", "results", "metrics", "list", "items", "folders"]
        for key in keys {
            if let array = dict[key] as? [Any] {
                return array
            }
        }
        return []
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

    static func formatNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}
