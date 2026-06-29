//
//  APILogger.swift
//  Apollo360
//
//  Created by Amit Sinha on 18/01/26.
//

import Foundation
import os

enum APILogger {

    private static let line = String(repeating: "─", count: 50)
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Apollo360", category: "API")

    // MARK: - Request Log
    static func logRequest(
        endpoint: String,
        url: String,
        method: String,
        headers: [String: String]?,
        body: Data?
    ) {
        logger.debug("""

        \(line)
        📤 API REQUEST
        Endpoint : \(endpoint)
        URL      : \(url)
        Method   : \(method)
        Headers  : \(headers ?? [:])
        \(line)
        \(body.flatMap { prettyJSON(from: $0) } ?? "No Body")
        \(line)
        """)
    }

    // MARK: - Response Log
    static func logResponse(
        endpoint: String,
        url: String,
        statusCode: Int,
        data: Data
    ) {
        logger.debug("""

        \(line)
        🌐 API RESPONSE
        Endpoint : \(endpoint)
        URL      : \(url)
        Status   : \(statusCode)
        Size     : \(data.count) bytes
        \(line)
        \(prettyJSON(from: data))
        \(line)
        """)
    }

    // MARK: - Error Log
    static func logError(
        endpoint: String,
        url: String,
        error: Error
    ) {
        logger.error("""

        \(line)
        ❌ API ERROR
        Endpoint : \(endpoint)
        URL      : \(url)
        Error    : \(error.localizedDescription)
        \(line)
        """)
    }

    // MARK: - JSON Formatter
    private static func prettyJSON(from data: Data) -> String {
        do {
            let object = try JSONSerialization.jsonObject(with: data)
            let prettyData = try JSONSerialization.data(
                withJSONObject: object,
                options: [.prettyPrinted, .sortedKeys]
            )
            return String(decoding: prettyData, as: UTF8.self)
        } catch {
            return String(decoding: data, as: UTF8.self)
        }
    }
}

