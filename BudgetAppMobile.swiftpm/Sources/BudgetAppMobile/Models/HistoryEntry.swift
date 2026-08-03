import Foundation

struct HistoryEntry: Codable, Equatable, Identifiable {
    var at: String
    var action: String
    var summary: String

    var id: String { at + action + summary }

    var date: Date? { Formatters.iso.date(from: at) }
}
