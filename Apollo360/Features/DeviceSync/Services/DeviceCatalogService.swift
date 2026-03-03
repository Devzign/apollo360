import Foundation

protocol DeviceCatalogServicing {
    func fetchStaticCatalog() async throws -> [StaticDeviceCatalogItem]
}

final class DeviceCatalogService: DeviceCatalogServicing {
    private let session: URLSession
    private let endpoint = URL(string: "https://ioapollo.com/surveys/static_response")

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchStaticCatalog() async throws -> [StaticDeviceCatalogItem] {
        guard let endpoint else {
            throw DeviceSyncError.invalidURL
        }

        let (data, response) = try await session.data(from: endpoint)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw DeviceSyncError.invalidResponse
        }

        let json = try JSONSerialization.jsonObject(with: data)
        return parseCatalog(from: json)
    }

    private func parseCatalog(from root: Any) -> [StaticDeviceCatalogItem] {
        var results: [StaticDeviceCatalogItem] = []

        func walk(_ node: Any) {
            if let dict = node as? [String: Any] {
                let sourceType =
                    (dict["type"] as? String) ??
                    (dict["source_type"] as? String) ??
                    (dict["slug"] as? String)
                let displayName =
                    (dict["display_name"] as? String) ??
                    (dict["name"] as? String) ??
                    (dict["title"] as? String)

                if let sourceType, !sourceType.isEmpty {
                    let mappedType = DeviceSourceType(rawType: sourceType)
                    let label = displayName ?? mappedType.displayName
                    results.append(
                        StaticDeviceCatalogItem(sourceType: sourceType, displayName: label)
                    )
                }

                dict.values.forEach { walk($0) }
                return
            }

            if let array = node as? [Any] {
                array.forEach { walk($0) }
            }
        }

        walk(root)

        var deduped: [String: StaticDeviceCatalogItem] = [:]
        results.forEach { item in
            let key = item.sourceType
                .lowercased()
                .replacingOccurrences(of: " ", with: "_")
            deduped[key] = item
        }

        if deduped.isEmpty {
            return DeviceSourceType.displayMappingTable.map { pair in
                StaticDeviceCatalogItem(sourceType: pair.key, displayName: pair.value)
            }
        }

        return Array(deduped.values).sorted { $0.displayName < $1.displayName }
    }
}
