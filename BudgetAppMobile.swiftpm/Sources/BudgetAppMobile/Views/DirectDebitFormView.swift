import SwiftUI

/// Add/edit sheet — mirrors the fields in DebitRow / NewDebitRow from the
/// web app's DirectDebits.jsx (name, vendor, frequency, due day, payment,
/// amount, status, tags, comment).
struct DirectDebitFormView: View {
    enum Mode { case add, edit(DirectDebit) }

    let mode: Mode
    let onSave: (DirectDebit) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var vendor: String
    @State private var frequency: String
    @State private var dueDay: String
    @State private var payment: String
    @State private var amount: String
    @State private var status: String
    @State private var comment: String
    @State private var tagInput: String

    init(mode: Mode, onSave: @escaping (DirectDebit) -> Void) {
        self.mode = mode
        self.onSave = onSave
        let item: DirectDebit
        switch mode {
        case .add: item = DirectDebit()
        case .edit(let existing): item = existing
        }
        _name = State(initialValue: item.name)
        _vendor = State(initialValue: item.vendor ?? "")
        _frequency = State(initialValue: item.frequency)
        _dueDay = State(initialValue: item.dueDay.map { String($0) } ?? "")
        _payment = State(initialValue: item.payment)
        _amount = State(initialValue: item.amount == 0 ? "" : String(item.amount))
        _status = State(initialValue: item.status)
        _comment = State(initialValue: item.comment ?? "")
        _tagInput = State(initialValue: item.tags.joined(separator: ", "))
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(amount) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    TextField("Vendor", text: $vendor)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    HStack {
                        Text("Due day")
                        Spacer()
                        TextField("1–31", text: $dueDay)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }

                Section("Payment") {
                    Picker("Account", selection: $payment) {
                        ForEach(PaymentAccount.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                    }
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    Picker("Status", selection: $status) {
                        ForEach(DebitStatus.allCases, id: \.rawValue) { Text($0.rawValue).tag($0.rawValue) }
                    }
                }

                Section("Tags & notes") {
                    TextField("Tags, comma separated", text: $tagInput)
                    TextField("Comment", text: $comment, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isAdding ? "Add Direct Debit" : "Edit Direct Debit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!isValid)
                }
            }
        }
    }

    private var isAdding: Bool {
        if case .add = mode { return true }
        return false
    }

    private func save() {
        var item: DirectDebit
        if case .edit(let existing) = mode {
            item = existing
        } else {
            item = DirectDebit()
        }
        item.name = name.trimmingCharacters(in: .whitespaces)
        item.vendor = vendor.isEmpty ? nil : vendor
        item.frequency = frequency
        item.dueDay = Int(dueDay)
        item.payment = payment
        item.amount = Double(amount) ?? 0
        item.status = status
        item.comment = comment.isEmpty ? nil : comment
        item.tags = tagInput.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        onSave(item)
        dismiss()
    }
}
