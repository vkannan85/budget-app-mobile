import SwiftUI

struct DirectDebitsListView: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var store = DirectDebitsStore()

    @State private var showingAddSheet = false
    @State private var editingItem: DirectDebit?
    @State private var isSelecting = false
    @State private var pendingDelete: DirectDebit?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    monthNav
                    SummaryCardsView(store: store)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 6)
                    filterChips
                }
                .listRowSeparator(.hidden)

                Section {
                    if store.filteredItems.isEmpty {
                        Text(store.isFiltered ? "No matching entries." : "No direct debits yet — tap + to add one.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(store.filteredItems) { item in
                            DirectDebitRowView(
                                item: item,
                                dueSoon: Formatters.isDueSoon(item, activeMonth: store.activeMonth),
                                isSelecting: isSelecting,
                                isSelected: store.selectedIDs.contains(item.id),
                                onToggleSelect: { store.toggleSelected(item.id) },
                                onEdit: { editingItem = item }
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { pendingDelete = item } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { editingItem = item } label: {
                                    Label("Edit", systemImage: "pencil")
                                }.tint(.indigo)
                            }
                        }
                    }
                } header: {
                    Text("\(store.filteredItems.count) entries")
                } footer: {
                    HStack {
                        Text(store.isFiltered ? "Filtered total" : "Total")
                        Spacer()
                        Text(Formatters.money(store.isFiltered ? store.filteredTotal : store.total))
                            .fontWeight(.semibold)
                    }
                }
            }
            .searchable(text: $store.searchQuery, prompt: "Search name")
            .listStyle(.insetGrouped)
            .navigationTitle("Direct Debits")
            .refreshable { await store.load() }
            .toolbar { toolbarContent }
            .task { await store.load() }
            .sheet(isPresented: $showingAddSheet) {
                DirectDebitFormView(mode: .add) { item in
                    Task { await store.add(DirectDebitPayload(from: withMonth(item))) }
                }
            }
            .sheet(item: $editingItem) { item in
                DirectDebitFormView(mode: .edit(item)) { updated in
                    Task { await store.save(updated, changeNote: item) }
                }
            }
            .alert("Delete entry?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let item = pendingDelete { Task { await store.delete(item) } }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text(pendingDelete.map { "\"\($0.name)\" will be permanently removed." } ?? "")
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK") { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }

    private func withMonth(_ item: DirectDebit) -> DirectDebit {
        var copy = item
        copy.month = store.activeMonth
        return copy
    }

    private var monthNav: some View {
        HStack {
            Button { store.goToPreviousMonth() } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(Formatters.displayMonth(store.activeMonth)).font(.headline)
            Spacer()
            Button { store.goToNextMonth() } label: { Image(systemName: "chevron.right") }
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
    }

    private var filterChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(["All"] + DebitStatus.allCases.map(\.rawValue), id: \.self) { s in
                        chip(s, selected: store.statusFilter == s) { store.statusFilter = s }
                    }
                    Divider().frame(height: 16)
                    ForEach(["All"] + PaymentAccount.allCases.map(\.rawValue), id: \.self) { p in
                        chip(p, selected: store.paymentFilter == p) { store.paymentFilter = p }
                    }
                }
            }
            if !store.allTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(store.allTags, id: \.self) { tag in
                            chip("#\(tag)", selected: store.tagFilter == tag) {
                                store.tagFilter = store.tagFilter == tag ? nil : tag
                            }
                        }
                    }
                }
            }
        }
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selected ? Color.indigo : Color(.tertiarySystemFill), in: Capsule())
                .foregroundStyle(selected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button(isSelecting ? "Done Selecting" : "Select") {
                    isSelecting.toggle()
                    if !isSelecting { store.selectedIDs.removeAll() }
                }
                if isSelecting && !store.selectedIDs.isEmpty {
                    Button("Mark \(store.selectedIDs.count) Paid") {
                        Task { await store.markSelectedPaid() }
                    }
                }
                Button(store.hasNextMonth ? "Sync to \(store.nextMonthDisplay)" : "Copy to \(store.nextMonthDisplay)") {
                    Task { await store.copyToNextMonth() }
                }
                Button("Sign Out", role: .destructive) { auth.logout() }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            if store.isBusy {
                ProgressView()
            } else {
                Button { showingAddSheet = true } label: { Image(systemName: "plus") }
            }
        }
    }
}
