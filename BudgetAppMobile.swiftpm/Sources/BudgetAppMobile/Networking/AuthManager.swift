import Foundation
import Combine

/// Holds the JWT in memory only — you're logged out on every app relaunch.
/// This mirrors what was chosen for v1 (no Keychain persistence yet); add
/// Keychain storage later if re-entering the password each launch gets old.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var token: String?
    @Published var errorMessage: String?
    @Published var isLoggingIn = false

    var isAuthenticated: Bool { token != nil }

    private init() {}

    func login(username: String, password: String) async {
        errorMessage = nil
        isLoggingIn = true
        defer { isLoggingIn = false }

        var request = URLRequest(url: Config.apiBaseURL.appendingPathComponent("auth/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["username": username, "password": password])

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                errorMessage = "No response from server."
                return
            }
            guard http.statusCode == 200 else {
                let body = try? JSONDecoder().decode([String: String].self, from: data)
                errorMessage = body?["error"] ?? "Login failed (\(http.statusCode))."
                return
            }
            let decoded = try JSONDecoder().decode([String: String].self, from: data)
            token = decoded["token"]
        } catch {
            errorMessage = "Couldn't reach the server: \(error.localizedDescription)"
        }
    }

    func logout() {
        token = nil
    }
}
