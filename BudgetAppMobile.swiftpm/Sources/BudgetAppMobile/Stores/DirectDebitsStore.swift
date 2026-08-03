import Foundation
import Combine

/// Ports the state/logic from budget-app-railway/frontend/src/pages/DirectDebits.jsx.
/// "Month" here means the `month` field on each item (a "yyyy-MM" tag, unrelated
/// to calendar dates) — entries with no month are "global" and apply to every
/// month unless a month-specific copy with the same name overrides them.
@MainActor
final class DirectDebitsStore: ObservableObject {
    @Published private(set) var items: [DirectDebit] = []
    @Published var activeMonth: String = Formatters.currentMonthKey()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var statusFilter: String = "All"          // "All" | DebitStatus
    @Published var paymentFilter: String = "All"         // "All" | PaymentAccount
    @Published var tagFilter: String? = nil
    @Published var searchQuery: String = ""
    @Published var selectedIDs: Set<String> = []
    @Published var isBusy = false

    private let api = DirectDebitsAPI()

    // MARK: - Loading

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            items = try await api.list()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Month partitioning (mirrors monthItems in DirectDebits.jsx)

    var monthSpecificItems: [DirectDebit] { items.filter { $0.month == activeMonth } }

    private var monthSpecificNames: Set<String> { Set(monthSpecificItems.map(\.name)) }

    private var globalItems: [DirectDebit] {
        items.filter { $0.month == nil && !monthSpecificNames.contains($0.name) }
    }

    var monthItems: [DirectDebit] { globalItems + monthSpecificItems }

    var nextMonthKey: String { Formatters.addMonths(activeMonth, 1) }
    var nextMonthDisplay: String { Formatters.displayMonth(nextMonthKey) }
    private var nextMonthItems: [DirectDebit] { items.filter { $0.month == nextMonthKey } }
    var hasNextMonth: Bool { !nextMonthItems.isEmpty }

    var allTags: [String] {
        Array(Set(monthItems.flatMap(\.tags))).sorted()
    }

    var filteredItems: [DirectDebit] {
        monthItems
            .filter { statusFilter == "All" || $0.status == statusFilter }
            .filter { paymentFilter == "All" || $0.payment == paymentFilter }
            .filter { tagFilter == nil || $0.tags.contains(tagFilter!) }
            .filter { searchQuery.isEmpty || $0.name.localizedCaseInsensitiveContains(searchQuery) }
            .sorted { ($0.dueDay ?? 999, $0.name) < ($1.dueDay ?? 999, $1.name) }
    }

    var total: Double { monthItems.reduce(0) { $0 + $1.amount } }
    var filteredTotal: Double { filteredItems.reduce(0) { $0 + $1.amount } }
    var isFiltered: Bool { statusFilter != "All" || paymentFilter != "All" || tagFilter != nil || !searchQuery.isEmpty }

    func total(for payment: String) -> Double {
        monthItems.filter { $0.payment == payment }.reduce(0) { $0 + $1.amount }
    }

    func total(for status: String, in scope: [DirectDebit]? = nil) -> Double {
        (scope ?? monthItems).filter { $0.status == status }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Navigation

    func goToPreviousMonth() { activeMonth = Formatters.addMonths(activeMonth, -1) }
    func goToNextMonth() { activeMonth = Formatters.addMonths(activeMonth, 1) }

    // MARK: - Mutations

    func add(_ payload: DirectDebitPayload) async {
        do {
            _ = try await api.create(payload)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(_ item: DirectDebit, action: String = "Updated", changeNote: DirectDebit? = nil) async {
        var updated = item
        if let before = changeNote {
            updated.history.append(historyEntry(before: before, after: item, action: action))
        }
        do {
            _ = try await api.update(id: item.id, DirectDebitPayload(from: updated))
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ item: DirectDebit) async {
        do {
            try await api.remove(id: item.id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markSelectedPaid() async {
        let selected = filteredItems.filter { selectedIDs.contains($0.id) }
        guard !selected.isEmpty else { return }
        isBusy = true
        defer { isBusy = false }
        for item in selected {
            var next = item
            next.status = DebitStatus.paid.rawValue
            next.history.append(historyEntry(before: item, after: next, action: "Bulk marked paid"))
            do {
                _ = try await api.update(id: item.id, DirectDebitPayload(from: next))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        selectedIDs.removeAll()
        await load()
    }

    /// Copies this month's entries into next month: existing same-name entries
    /// next month are overwritten and reset to "In Due"; new ones are created.
    /// Next-month entries with no counterpart this month are left untouched.
    func copyToNextMonth() async {
        let target = nextMonthKey
        let nextByName = Dictionary(uniqueKeysWithValues: nextMonthItems.map { ($0.name, $0) })
        let toUpdate = monthItems.filter { nextByName[$0.name] != nil }
        let toCreate = monthItems.filter { nextByName[$0.name] == nil }

        isBusy = true
        defer { isBusy = false }

        for item in toUpdate {
            guard let targetItem = nextByName[item.name] else { continue }
            var rest = item
            rest.month = target
            rest.status = DebitStatus.inDue.rawValue
            do {
                _ = try await api.update(id: targetItem.id, DirectDebitPayload(from: rest))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        for item in toCreate {
            var rest = item
            rest.month = target
            rest.status = DebitStatus.inDue.rawValue
            do {
                _ = try await api.create(DirectDebitPayload(from: rest))
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        await load()
    }

    func toggleSelected(_ id: String) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
    }

    // MARK: - History summary (mirrors historyEntry() in DirectDebits.jsx)

    private func historyEntry(before: DirectDebit, after: DirectDebit, action: String) -> HistoryEntry {
        var changes: [String] = []
        if before.amount != after.amount {
            changes.append("amount \(Formatters.money(before.amount)) to \(Formatters.money(after.amount))")
        }
        if before.status != after.status {
            changes.append("status \(before.status) to \(after.status)")
        }
        if (before.comment ?? "") != (after.comment ?? "") {
            changes.append("comment changed")
        }
        if before.payment != after.payment {
            changes.append("payment \(before.payment) to \(after.payment)")
        }
        return HistoryEntry(
            at: Formatters.iso.string(from: Date()),
            action: action,
            summary: changes.isEmpty ? action : changes.joined(separator: ", ")
        )
    }
}
