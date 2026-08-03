import SwiftUI

/// Mirrors the "Payment Summary" / "Status Summary" cards at the top of
/// DirectDebits.jsx.
struct SummaryCardsView: View {
    @ObservedObject var store: DirectDebitsStore

    var body: some View {
        VStack(spacing: 12) {
            card(title: "Payment Summary", icon: "creditcard.fill") {
                ForEach(PaymentAccount.allCases, id: \.rawValue) { p in
                    row(p.rawValue, Formatters.money(store.total(for: p.rawValue)))
                }
            }
            card(title: "Status Summary", icon: "checkmark.seal.fill") {
                row("Paid", Formatters.money(store.total(for: DebitStatus.paid.rawValue)), dotColor: .green)
                row("In Due", Formatters.money(store.total(for: DebitStatus.inDue.rawValue)), dotColor: .yellow)
            }
        }
    }

    @ViewBuilder
    private func card<Content: View>(title: String, icon: String, @ViewBuilder rows: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: icon)
                Text(title).font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [.slateDark, .slateDarker], startPoint: .leading, endPoint: .trailing))

            VStack(spacing: 0) { rows() }
                .padding(.horizontal, 14)
                .padding(.vertical, 4)

            HStack {
                Text("Total").font(.caption.weight(.semibold))
                Spacer()
                Text(Formatters.money(store.total)).font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(LinearGradient(colors: [.slateDark, .slateDarker], startPoint: .leading, endPoint: .trailing))
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func row(_ label: String, _ value: String, dotColor: Color? = nil) -> some View {
        HStack {
            if let dotColor {
                Circle().fill(dotColor).frame(width: 6, height: 6)
            }
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.caption.weight(.semibold))
        }
        .padding(.vertical, 6)
    }
}

private extension Color {
    static let slateDark = Color(red: 0.29, green: 0.33, blue: 0.41)
    static let slateDarker = Color(red: 0.20, green: 0.24, blue: 0.31)
}
