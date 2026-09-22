import AuthenticationServices
import CryptoKit
import Foundation
import Security
import UIKit

enum SalesforceClientError: LocalizedError {
    case invalidConfiguration
    case authenticationCancelled
    case invalidCallback
    case invalidResponse
    case server(String)
    case notConnected

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration: "Enter the Consumer Key from your Salesforce External Client App."
        case .authenticationCancelled: "Salesforce sign-in was cancelled."
        case .invalidCallback: "Salesforce returned an invalid sign-in response. Check the callback URL."
        case .invalidResponse: "Salesforce returned an unexpected response."
        case .server(let message): message
        case .notConnected: "Connect to Salesforce before exporting."
        }
    }
}

@MainActor
final class SalesforceClient: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    static let callbackURL = "d2dcrm://oauth/salesforce"

    @Published private(set) var isConnected = false
    @Published private(set) var organizationName: String?

    private let session: URLSession
    private var authenticationSession: ASWebAuthenticationSession?
    private var accessToken: String?
    private var instanceURL: URL?
    private var refreshToken: String? { SalesforceKeychain.string(for: "salesforce.refreshToken") }

    override init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 45
        session = URLSession(configuration: configuration)
        super.init()
        isConnected = refreshToken != nil
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindow = scenes.flatMap(\.windows).first(where: \.isKeyWindow) {
            return keyWindow
        }
        guard let scene = scenes.first else {
            preconditionFailure("Salesforce sign-in requires an active window scene.")
        }
        return UIWindow(windowScene: scene)
    }

    func connect(clientID: String, environment: SalesforceEnvironment) async throws {
        let trimmedClientID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedClientID.isEmpty else { throw SalesforceClientError.invalidConfiguration }

        let verifier = Self.randomURLSafeString()
        let challenge = Self.base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
        let state = Self.randomURLSafeString()
        var components = URLComponents(url: environment.loginURL.appending(path: "services/oauth2/authorize"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: trimmedClientID),
            URLQueryItem(name: "redirect_uri", value: Self.callbackURL),
            URLQueryItem(name: "scope", value: "api refresh_token"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        guard let authorizationURL = components?.url else { throw SalesforceClientError.invalidConfiguration }

        let callback = try await authenticate(at: authorizationURL)
        guard let callbackComponents = URLComponents(url: callback, resolvingAgainstBaseURL: false),
              callbackComponents.queryValue(named: "state") == state,
              let code = callbackComponents.queryValue(named: "code") else {
            throw SalesforceClientError.invalidCallback
        }

        let token: TokenResponse = try await formRequest(
            environment.loginURL.appending(path: "services/oauth2/token"),
            values: [
                "grant_type": "authorization_code",
                "client_id": trimmedClientID,
                "redirect_uri": Self.callbackURL,
                "code": code,
                "code_verifier": verifier
            ]
        )
        try accept(token: token)
        UserDefaults.standard.set(trimmedClientID, forKey: "salesforce.clientID")
        UserDefaults.standard.set(environment.rawValue, forKey: "salesforce.environment")
    }

    func disconnect() {
        accessToken = nil
        instanceURL = nil
        organizationName = nil
        isConnected = false
        SalesforceKeychain.delete("salesforce.refreshToken")
    }

    func fields(
        for object: SalesforceObjectType,
        clientID: String,
        environment: SalesforceEnvironment
    ) async throws -> [SalesforceField] {
        try await ensureAccessToken(clientID: clientID, environment: environment)
        let version = try await latestAPIVersion()
        let response: DescribeResponse = try await authorizedRequest(path: "/services/data/v\(version)/sobjects/\(object.rawValue)/describe")
        organizationName = instanceURL?.host
        return response.fields
            .filter { $0.createable && !$0.calculated && !["address", "location", "base64"].contains($0.type) }
            .map { SalesforceField(name: $0.name, label: $0.label, type: $0.type, isRequired: !$0.nillable && !$0.defaultedOnCreate) }
            .sorted { lhs, rhs in
                if lhs.isRequired != rhs.isRequired { return lhs.isRequired }
                return lhs.label.localizedCaseInsensitiveCompare(rhs.label) == .orderedAscending
            }
    }

    func export(
        records: [SalesforceExportRecord],
        object: SalesforceObjectType,
        mappings: [SalesforceFieldMapping],
        clientID: String,
        environment: SalesforceEnvironment
    ) async throws -> SalesforceExportResult {
        try await ensureAccessToken(clientID: clientID, environment: environment)
        let version = try await latestAPIVersion()
        var succeeded = 0
        var failures: [String] = []

        for batch in records.chunked(into: 200) {
            let payloadRecords: [[String: Any]] = batch.map { record in
                var payload: [String: Any] = ["attributes": ["type": object.rawValue]]
                for mapping in mappings {
                    guard let destination = mapping.destinationName,
                          let value = record.value(for: mapping.source) else { continue }
                    payload[destination] = Self.convert(value, for: destination)
                }
                if object == .lead {
                    payload["LastName"] = payload["LastName"] ?? record.value(for: .lastName) ?? "Unknown"
                    payload["Company"] = payload["Company"] ?? record.value(for: .company) ?? "Individual"
                } else {
                    payload["LastName"] = payload["LastName"] ?? record.value(for: .lastName) ?? "Unknown"
                }
                return payload
            }
            let body: [String: Any] = ["allOrNone": false, "records": payloadRecords]
            let response: CompositeCreateResponse = try await authorizedJSONRequest(
                path: "/services/data/v\(version)/composite/sobjects",
                method: "POST",
                body: body
            )
            for result in response {
                if result.success { succeeded += 1 }
                else { failures.append(contentsOf: result.errors.map(\.message)) }
            }
        }
        return SalesforceExportResult(succeeded: succeeded, failedMessages: failures)
    }

    private func ensureAccessToken(clientID: String, environment: SalesforceEnvironment) async throws {
        guard accessToken == nil else { return }
        guard let refreshToken else { throw SalesforceClientError.notConnected }
        let token: TokenResponse = try await formRequest(
            environment.loginURL.appending(path: "services/oauth2/token"),
            values: ["grant_type": "refresh_token", "client_id": clientID, "refresh_token": refreshToken]
        )
        try accept(token: token)
    }

    private func accept(token: TokenResponse) throws {
        guard let url = URL(string: token.instanceURL) else { throw SalesforceClientError.invalidResponse }
        accessToken = token.accessToken
        instanceURL = url
        if let refreshToken = token.refreshToken { SalesforceKeychain.set(refreshToken, for: "salesforce.refreshToken") }
        isConnected = true
    }

    private func authenticate(at url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let webSession = ASWebAuthenticationSession(url: url, callbackURLScheme: "d2dcrm") { callback, error in
                if let authenticationError = error as? ASWebAuthenticationSessionError,
                   authenticationError.code == .canceledLogin {
                    continuation.resume(throwing: SalesforceClientError.authenticationCancelled)
                } else if let error {
                    continuation.resume(throwing: error)
                } else if let callback {
                    continuation.resume(returning: callback)
                } else {
                    continuation.resume(throwing: SalesforceClientError.invalidCallback)
                }
            }
            webSession.presentationContextProvider = self
            webSession.prefersEphemeralWebBrowserSession = false
            authenticationSession = webSession
            webSession.start()
        }
    }

    private func latestAPIVersion() async throws -> String {
        let versions: [VersionResponse] = try await authorizedRequest(path: "/services/data")
        guard let version = versions.last?.version else { throw SalesforceClientError.invalidResponse }
        return version
    }

    private func authorizedRequest<T: Decodable>(path: String) async throws -> T {
        try await authorizedJSONRequest(path: path, method: "GET", body: nil)
    }

    private func authorizedJSONRequest<T: Decodable>(path: String, method: String, body: [String: Any]?) async throws -> T {
        guard let accessToken, let instanceURL else { throw SalesforceClientError.notConnected }
        var request = URLRequest(url: instanceURL.appending(path: path))
        request.httpMethod = method
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        return try JSONDecoder.salesforce.decode(T.self, from: data)
    }

    private func formRequest<T: Decodable>(_ url: URL, values: [String: String]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = values
            .map { "\(Self.formEncode($0.key))=\(Self.formEncode($0.value))" }
            .sorted()
            .joined(separator: "&")
            .data(using: .utf8)
        let (data, response) = try await session.data(for: request)
        try Self.validate(response: response, data: data)
        return try JSONDecoder.salesforce.decode(T.self, from: data)
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let response = response as? HTTPURLResponse else { throw SalesforceClientError.invalidResponse }
        guard (200...299).contains(response.statusCode) else {
            let message = (try? JSONDecoder().decode(OAuthError.self, from: data).errorDescription)
                ?? (try? JSONDecoder().decode([APIError].self, from: data).first?.message)
                ?? "Salesforce request failed (HTTP \(response.statusCode))."
            throw SalesforceClientError.server(message)
        }
    }

    private static func randomURLSafeString() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return base64URL(Data(bytes))
    }

    private static func base64URL(_ data: Data) -> String {
        data.base64EncodedString().replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
    }

    private static func formEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
    }

    private static func convert(_ value: String, for destination: String) -> Any {
        if ["NumberOfEmployees", "Knock_Count__c"].contains(destination), let number = Int(value) { return number }
        if destination.localizedCaseInsensitiveContains("latitude") || destination.localizedCaseInsensitiveContains("longitude"),
           let number = Double(value) { return number }
        return value
    }
}

private struct TokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let instanceURL: String
}

private struct VersionResponse: Decodable { let version: String }
private struct DescribeResponse: Decodable { let fields: [DescribeField] }
private struct DescribeField: Decodable {
    let name: String
    let label: String
    let type: String
    let createable: Bool
    let calculated: Bool
    let nillable: Bool
    let defaultedOnCreate: Bool
}
private typealias CompositeCreateResponse = [CompositeCreateResult]
private struct CompositeCreateResult: Decodable {
    let success: Bool
    let errors: [APIError]
}
private struct APIError: Decodable { let message: String }
private struct OAuthError: Decodable {
    let errorDescription: String
    enum CodingKeys: String, CodingKey { case errorDescription = "error_description" }
}

private extension JSONDecoder {
    static var salesforce: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

private extension URLComponents {
    func queryValue(named name: String) -> String? { queryItems?.first { $0.name == name }?.value }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0 + size, count)]) }
    }
}

private enum SalesforceKeychain {
    static func set(_ value: String, for account: String) {
        delete(account)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "d2d-crm",
            kSecAttrAccount as String: account,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func string(for account: String) -> String? {
        var query: [String: Any] = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(_ account: String) { SecItemDelete(baseQuery(account) as CFDictionary) }

    private static func baseQuery(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: Bundle.main.bundleIdentifier ?? "d2d-crm",
         kSecAttrAccount as String: account]
    }
}
