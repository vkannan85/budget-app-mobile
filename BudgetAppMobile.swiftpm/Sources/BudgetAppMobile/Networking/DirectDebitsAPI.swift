import Foundation

/// Maps 1:1 onto budget-app-railway/backend/routes/directDebits.js and the
/// `directDebits` export in frontend/src/api/client.js.
struct DirectDebitsAPI {
    private let client = APIClient.shared

    func list() async throws -> [DirectDebit] {
        try await client.request("direct-debits")
    }

    @discardableResult
    func create(_ payload: DirectDebitPayload) async throws -> DirectDebit {
        try await client.request("direct-debits", method: "POST", body: payload)
    }

    @discardableResult
    func update(id: String, _ payload: DirectDebitPayload) async throws -> DirectDebit {
        try await client.request("direct-debits/\(id)", method: "PUT", body: payload)
    }

    func remove(id: String) async throws {
        try await client.requestNoContent("direct-debits/\(id)", method: "DELETE")
    }
}
