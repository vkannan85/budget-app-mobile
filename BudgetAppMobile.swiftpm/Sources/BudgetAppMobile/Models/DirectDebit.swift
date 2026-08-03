import Foundation

enum Frequency: String, CaseIterable, Codable {
    case monthly = "Monthly"
    case weekly = "Weekly"
    case quarterly = "Quarterly"
    case annually = "Annually"
}

enum DebitStatus: String, CaseIterable, Codable {
    case inDue = "In Due"
    case paid = "Paid"
}

/// Payment accounts. Matches the web app's `PAYMENTS` list — edit if you add
/// or rename an account there.
enum PaymentAccount: String, CaseIterable, Codable {
    case lloyds = "Lloyds Account"
    case monzo = "Monzo Account"
}

/// A direct debit entry, as stored in the `direct_debits` Postgres table
/// (JSONB `data` column). Fields are decoded leniently because the source
/// data was migrated from Azure Table Storage, where numbers were sometimes
/// serialised as strings (see budget-app-railway/CLAUDE.md).
struct DirectDebit: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var vendor: String?
    var frequency: String
    var dueDay: Int?
    var payment: String
    var amount: Double
    var status: String
    var comment: String?
    var tags: [String]
    var history: [HistoryEntry]
    var month: String?
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, vendor, frequency, dueDay, payment, amount, status, comment, tags, history, month, createdAt
    }

    init(
        id: String = UUID().uuidString,
        name: String = "",
        vendor: String? = nil,
        frequency: String = Frequency.monthly.rawValue,
        dueDay: Int? = nil,
        payment: String = PaymentAccount.lloyds.rawValue,
        amount: Double = 0,
        status: String = DebitStatus.inDue.rawValue,
        comment: String? = nil,
        tags: [String] = [],
        history: [HistoryEntry] = [],
        month: String? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.vendor = vendor
        self.frequency = frequency
        self.dueDay = dueDay
        self.payment = payment
        self.amount = amount
        self.status = status
        self.comment = comment
        self.tags = tags
        self.history = history
        self.month = month
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        vendor = try c.decodeIfPresent(String.self, forKey: .vendor)
        frequency = try c.decodeIfPresent(String.self, forKey: .frequency) ?? Frequency.monthly.rawValue
        dueDay = Self.decodeFlexibleInt(c, .dueDay)
        payment = try c.decodeIfPresent(String.self, forKey: .payment) ?? PaymentAccount.lloyds.rawValue
        amount = Self.decodeFlexibleDouble(c, .amount) ?? 0
        status = try c.decodeIfPresent(String.self, forKey: .status) ?? DebitStatus.inDue.rawValue
        comment = try c.decodeIfPresent(String.self, forKey: .comment)
        tags = try c.decodeIfPresent([String].self, forKey: .tags) ?? []
        history = try c.decodeIfPresent([HistoryEntry].self, forKey: .history) ?? []
        month = try c.decodeIfPresent(String.self, forKey: .month)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
    }

    private static func decodeFlexibleInt(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Int? {
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
        if let v = try? c.decodeIfPresent(Double.self, forKey: key) { return Int(v) }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) { return Int(s) }
        return nil
    }

    private static func decodeFlexibleDouble(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double? {
        if let v = try? c.decodeIfPresent(Double.self, forKey: key) { return v }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) { return Double(s) }
        return nil
    }
}

/// Body sent on create (POST) / replace (PUT). The backend generates `id` and
/// `createdAt` itself on create; PUT expects the full replacement document.
struct DirectDebitPayload: Encodable {
    var name: String
    var vendor: String
    var frequency: String
    var dueDay: Int?
    var payment: String
    var amount: Double
    var status: String
    var comment: String
    var tags: [String]
    var history: [HistoryEntry]
    var month: String?

    init(from item: DirectDebit) {
        name = item.name
        vendor = item.vendor ?? ""
        frequency = item.frequency
        dueDay = item.dueDay
        payment = item.payment
        amount = item.amount
        status = item.status
        comment = item.comment ?? ""
        tags = item.tags
        history = item.history
        month = item.month
    }
}
