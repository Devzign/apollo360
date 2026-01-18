//
//  APILogger.swift
//  Apollo360
//
//  Created by Amit Sinha on 18/01/26.
//

import Foundation

enum APILogger {

    private static let line = String(repeating: "─", count: 50)

    // MARK: - Request Log
    static func logRequest(
        endpoint: String,
        method: String,
        headers: [String: String]?,
        body: Data?
    ) {
        print("""
        
        \(line)
        📤 API REQUEST
        Endpoint : \(endpoint)
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
        statusCode: Int,
        data: Data
    ) {
        print("""
        
        \(line)
        🌐 API RESPONSE
        Endpoint : \(endpoint)
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
        error: Error
    ) {
        print("""
        
        \(line)
        ❌ API ERROR
        Endpoint : \(endpoint)
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


