import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case server(status: Int, message: String)
    case transport(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Session expired — please log in again."
        case .server(let status, let message): return "\(message) (\(status))"
        case .transport(let error): return error.localizedDescription
        case .decoding(let error): return "Unexpected response from server: \(error.localizedDescription)"
        }
    }
}

/// Thin wrapper around URLSession for the JSON REST API served by
/// budget-app-railway/backend. Every call attaches the JWT from
/// AuthManager, matching the Bearer-token scheme `requireAuth` expects.
struct APIClient {
    static let shared = APIClient()

    private let baseURL = Config.apiBaseURL

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        let data = try await rawRequest(path, method: method, body: body)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

    /// For endpoints that return no body (e.g. DELETE -> 204).
    func requestNoContent(_ path: String, method: String, body: Encodable? = nil) async throws {
        _ = try await rawRequest(path, method: method, body: body)
    }

    private func rawRequest(_ path: String, method: String, body: Encodable?) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = await AuthManager.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.transport(URLError(.badServerResponse))
        }

        if http.statusCode == 401 {
            await AuthManager.shared.logout()
            throw APIError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Request failed"
            throw APIError.server(status: http.statusCode, message: message)
        }

        return data
    }
}

/// Type-erasing box so `request(_:method:body:)` can accept any Encodable.
private struct AnyEncodable: Encodable {
    private let encodeFn: (Encoder) throws -> Void
    init(_ wrapped: Encodable) { encodeFn = wrapped.encode }
    func encode(to encoder: Encoder) throws { try encodeFn(encoder) }
}
