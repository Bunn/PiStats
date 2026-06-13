//
//  DomainListView.swift
//  PiStats
//
//  Full-screen domain manager: lists the Pi-hole's allow/deny rules across the
//  four buckets (allow/deny × exact/regex) with add, per-row enable/disable and
//  delete. Loads on appear via injected closures and applies changes
//  optimistically, reverting on failure. Pushed like the blocklists screen.
//  Pi-hole v6 only — callers gate on version before passing the actions.
//

import SwiftUI
import PiStatsCore

/// The four domain operations a manager surface needs, injected so the view
/// stays decoupled from the data updater (mirrors AdListsView's closures).
struct DomainManagementActions {
    let loadAll: () async throws -> [DomainRule]
    let add: ([DomainRule]) async throws -> Void
    let remove: ([DomainRule]) async throws -> Void
    let setEnabled: (DomainRule, Bool) async throws -> Void
}

struct DomainListView: View {
    let actions: DomainManagementActions

    @State private var rules: [DomainRule] = []
    @State private var selectedType: DomainListType = .deny
    @State private var hasLoaded = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingAdd = false

    private func rules(for kind: DomainListKind) -> [DomainRule] {
        rules.filter { $0.type == selectedType && $0.kind == kind }
            .sorted { $0.domain.localizedCaseInsensitiveCompare($1.domain) == .orderedAscending }
    }

    var body: some View {
        List {
            Section {
                Picker("", selection: $selectedType) {
                    Text(UserText.allowDomainAction).tag(DomainListType.allow)
                    Text(UserText.blockDomainAction).tag(DomainListType.deny)
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.secondary)
                    Button("Retry") { Task { await reload() } }
                }
            } else {
                bucketSection(.exact, title: "Exact")
                bucketSection(.regex, title: "Regex")
            }
        }
        .overlay {
            if isLoading && !hasLoaded {
                ProgressView()
            }
        }
        .navigationTitle(UserText.domainsTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAdd = true
                } label: {
                    Label(UserText.addDomainTitle, systemImage: SystemImages.plus)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddDomainSheet(defaultType: selectedType) { rule in
                await add(rule)
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
    }

    @ViewBuilder
    private func bucketSection(_ kind: DomainListKind, title: String) -> some View {
        let items = rules(for: kind)
        Section {
            if hasLoaded && items.isEmpty {
                Text("None").foregroundStyle(.secondary)
            } else {
                ForEach(items) { rule in
                    Toggle(isOn: binding(for: rule)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.domain)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            if let comment = rule.comment, !comment.isEmpty {
                                Text(comment)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    #if os(macOS)
                    .toggleStyle(.switch)
                    #endif
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await delete(rule) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            Text(title)
        }
    }

    private func binding(for rule: DomainRule) -> Binding<Bool> {
        Binding(
            get: { rules.first(where: { $0.id == rule.id })?.enabled ?? rule.enabled },
            set: { newValue in Task { await setEnabled(rule, newValue) } }
        )
    }

    private func reload() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            rules = try await actions.loadAll()
            hasLoaded = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setEnabled(_ rule: DomainRule, _ enabled: Bool) async {
        applyLocal(rule, enabled: enabled) // optimistic
        do {
            try await actions.setEnabled(rule, enabled)
        } catch {
            applyLocal(rule, enabled: !enabled) // revert
            errorMessage = error.localizedDescription
        }
    }

    private func applyLocal(_ rule: DomainRule, enabled: Bool) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index].enabled = enabled
    }

    private func delete(_ rule: DomainRule) async {
        let previous = rules
        rules.removeAll { $0.id == rule.id } // optimistic
        do {
            try await actions.remove([rule])
        } catch {
            rules = previous // revert
            errorMessage = error.localizedDescription
        }
    }

    private func add(_ rule: DomainRule) async {
        do {
            try await actions.add([rule])
            await reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Add Sheet

private struct AddDomainSheet: View {
    let defaultType: DomainListType
    let onAdd: (DomainRule) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var domain = ""
    @State private var comment = ""
    @State private var type: DomainListType
    @State private var kind: DomainListKind = .exact
    @State private var isSubmitting = false

    init(defaultType: DomainListType, onAdd: @escaping (DomainRule) async -> Void) {
        self.defaultType = defaultType
        self.onAdd = onAdd
        _type = State(initialValue: defaultType)
    }

    private var trimmedDomain: String {
        domain.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(UserText.domainFieldPlaceholder, text: $domain)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                    TextField(UserText.commentFieldPlaceholder, text: $comment)
                }
                Section {
                    Picker(UserText.allowDomainAction + " / " + UserText.blockDomainAction, selection: $type) {
                        Text(UserText.allowDomainAction).tag(DomainListType.allow)
                        Text(UserText.blockDomainAction).tag(DomainListType.deny)
                    }
                    Picker("Match", selection: $kind) {
                        Text("Exact").tag(DomainListKind.exact)
                        Text("Regex").tag(DomainListKind.regex)
                    }
                }
            }
            .navigationTitle(UserText.addDomainTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { submit() }
                        .disabled(trimmedDomain.isEmpty || isSubmitting)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 360, minHeight: 240)
        #endif
    }

    private func submit() {
        let rule = DomainRule(
            domain: trimmedDomain,
            type: type,
            kind: kind,
            comment: comment.isEmpty ? nil : comment
        )
        isSubmitting = true
        Task {
            await onAdd(rule)
            dismiss()
        }
    }
}

// MARK: - Toast

/// A transient bottom banner used for confirming quick allow/block actions.
extension View {
    func domainActionToast(_ message: Binding<String?>) -> some View {
        modifier(ToastModifier(message: message))
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 24)
                        .shadow(radius: 8, y: 2)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task(id: message) {
                            try? await Task.sleep(for: .seconds(2))
                            self.message = nil
                        }
                }
            }
            .animation(.spring(duration: 0.3), value: message)
    }
}
