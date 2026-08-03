import Foundation

enum Formatters {
    static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoNoFraction: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    static func parseISO(_ s: String) -> Date? {
        iso.date(from: s) ?? isoNoFraction.date(from: s)
    }

    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "en_GB")
        f.currencyCode = "GBP"
        return f
    }()

    static func money(_ amount: Double) -> String {
        currency.string(from: NSNumber(value: amount)) ?? "£\(amount)"
    }

    /// "yyyy-MM" key used throughout the web app for the active pay month.
    private static let monthKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone.current
        return f
    }()

    private static let monthDisplayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f
    }()

    static func currentMonthKey() -> String {
        monthKeyFormatter.string(from: Date())
    }

    static func date(forMonthKey key: String) -> Date {
        monthKeyFormatter.date(from: key) ?? Date()
    }

    static func displayMonth(_ key: String) -> String {
        monthDisplayFormatter.string(from: date(forMonthKey: key))
    }

    static func addMonths(_ key: String, _ delta: Int) -> String {
        let base = date(forMonthKey: key)
        let next = Calendar.current.date(byAdding: .month, value: delta, to: base) ?? base
        return monthKeyFormatter.string(from: next)
    }

    /// Due date for a given day-of-month within `monthKey`, e.g. ("2026-08", 15) -> 2026-08-15.
    static func dueDate(monthKey: String, day: Int) -> Date? {
        var comps = Calendar.current.dateComponents([.year, .month], from: date(forMonthKey: monthKey))
        comps.day = day
        return Calendar.current.date(from: comps)
    }

    static func isDueSoon(_ item: DirectDebit, activeMonth: String) -> Bool {
        guard item.status != DebitStatus.paid.rawValue, let day = item.dueDay,
              let due = dueDate(monthKey: activeMonth, day: day) else { return false }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: Calendar.current.startOfDay(for: due)).day ?? -1
        return days >= 0 && days <= 5
    }

    static func ordinal(_ n: Int) -> String {
        let suffix: String
        let v = n % 100
        if (11...13).contains(v) {
            suffix = "th"
        } else {
            switch n % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(n)\(suffix)"
    }
}
