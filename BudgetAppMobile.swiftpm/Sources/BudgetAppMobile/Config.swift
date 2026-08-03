import Foundation

/// Points at the existing budget-app-railway backend so this app reads/writes
/// the same `direct_debits` table the web app uses. Change this if the
/// Railway custom domain ever changes.
enum Config {
    static let apiBaseURL = URL(string: "https://vkannan.store/api")!
}
