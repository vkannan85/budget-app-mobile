import SwiftUI

struct DirectDebitRowView: View {
    let item: DirectDebit
    let dueSoon: Bool
    let isSelecting: Bool
    let isSelected: Bool
    let onToggleSelect: () -> Void
    let onEdit: () -> Void

    private var isPaid: Bool { item.status == DebitStatus.paid.rawValue }

    var body: some View {
        HStack(spacing: 12) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .indigo : .secondary)
                    .onTapGesture(perform: onToggleSelect)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name).font(.subheadline.weight(.semibold))
                    if dueSoon {
                        Badge(text: "due soon", color: .orange)
                    }
                }
                HStack(spacing: 6) {
                    Text([item.vendor, item.frequency].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let day = item.dueDay {
                        Text("· \(Formatters.ordinal(day))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !item.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.tags, id: \.self) { tag in
                            Badge(text: tag, color: .indigo)
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(Formatters.money(item.amount)).font(.subheadline.weight(.semibold))
                Badge(text: item.status, color: isPaid ? .green : .yellow)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { isSelecting ? onToggleSelect() : onEdit() }
    }
}

private struct Badge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}
