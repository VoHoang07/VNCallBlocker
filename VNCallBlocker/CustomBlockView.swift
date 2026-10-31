import SwiftUI

struct CustomBlockView: View {
    @StateObject private var viewModel = CustomBlockViewModel()
    @State private var showAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Số tùy chỉnh")
                        .font(.title3.weight(.bold))
                    Text("\(viewModel.entries.count) mục • \(viewModel.totalCount.formatted()) số")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge
            }

            Divider()

            // Status
            HStack {
                Image(systemName: viewModel.status.isEnabled ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundStyle(viewModel.status.isEnabled ? .green : .orange)
                Text(viewModel.status.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(viewModel.status.isEnabled ? .green : .primary)
                Spacer()
            }

            // Action buttons
            HStack(spacing: 10) {
                Button {
                    showAddSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Thêm số chặn")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.purple.opacity(0.14))
                    .foregroundStyle(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                Button {
                    Task { await viewModel.reloadExtension() }
                } label: {
                    HStack(spacing: 6) {
                        if viewModel.isReloading {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(viewModel.isReloading ? "Đang nạp..." : "Cập nhật")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color.accentColor.opacity(0.14))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .disabled(viewModel.isReloading)
            }

            // Feedback
            if let msg = viewModel.feedbackMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: viewModel.feedbackIsError ? "xmark.octagon.fill" : "checkmark.circle.fill")
                    Text(msg)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(viewModel.feedbackIsError ? .red : .green)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((viewModel.feedbackIsError ? Color.red : Color.green).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            // Entries list
            if !viewModel.entries.isEmpty {
                DisclosureGroup("Danh sách \(viewModel.entries.count) mục đã thêm") {
                    VStack(spacing: 0) {
                        ForEach(viewModel.entries) { entry in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.label.isEmpty ? entry.rawInput : entry.label)
                                        .font(.caption.weight(.semibold))
                                    Text(entry.subtitle)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    viewModel.removeEntry(id: entry.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.top, 6)
                }
                .font(.footnote.weight(.medium))
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                    Text("Chưa có số tùy chỉnh nào. Nhấn \"Thêm số chặn\" để bắt đầu.")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showAddSheet) {
            viewModel.loadData()
        } content: {
            AddCustomBlockSheet(onSave: { entry in
                viewModel.addEntry(entry)
            })
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch viewModel.status {
        case .checking:
            ProgressView().controlSize(.small)
        case .enabled:
            Text("BẬT")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.green.opacity(0.18))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        case .disabled:
            Text("TẮT")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.orange.opacity(0.18))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        case .unknown, .error:
            Text("LỖI / CHƯA RÕ")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.red.opacity(0.15))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Add Sheet

struct AddCustomBlockSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (CustomBlockedEntry) -> Void

    @State private var inputMode: InputMode = .single
    @State private var phoneInput = ""
    @State private var prefixInput = ""
    @State private var label = ""
    @State private var errorMessage: String?

    enum InputMode: String, CaseIterable {
        case single = "Số cụ thể"
        case prefix = "Dải đầu số"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Loại chặn", selection: $inputMode) {
                        ForEach(InputMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("Ghi chú (tuỳ chọn)", text: $label)
                }

                switch inputMode {
                case .single:
                    Section {
                        TextField("VD: 02412345678 hoặc +842412345678", text: $phoneInput)
                            .keyboardType(.phonePad)
                    } header: {
                        Text("Số điện thoại cần chặn")
                    } footer: {
                        Text("Nhập số cố định VN đầy đủ (10-11 chữ số). Hỗ trợ định dạng: 024..., 028..., +8424..., 8424...")
                    }

                case .prefix:
                    Section {
                        TextField("VD: 02434 hoặc 024345", text: $prefixInput)
                            .keyboardType(.phonePad)
                    } header: {
                        Text("Đầu số cần chặn")
                    } footer: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nhập phần đầu số cần chặn. Hệ thống sẽ tự động pad thêm 0-9 để tạo dải số hoàn chỉnh.")
                            if let range = prefixPreview {
                                Text("Sẽ chặn: \(range.count.formatted()) số (\(range.lo)...\(range.hi))")
                                    .foregroundStyle(.purple)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Thêm số chặn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Huỷ") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var prefixPreview: (lo: String, hi: String, count: Int)? {
        guard !prefixInput.isEmpty,
              let (lo, hi) = VNPhoneParser.parsePrefix(prefixInput) else { return nil }
        return ("+\(lo)", "+\(hi)", Int(hi - lo) + 1)
    }

    private func save() {
        errorMessage = nil

        switch inputMode {
        case .single:
            guard let number = VNPhoneParser.parseSingle(phoneInput) else {
                errorMessage = "Số điện thoại không hợp lệ. Vui lòng nhập số cố định VN đầy đủ (VD: 02412345678)."
                return
            }
            let entry = CustomBlockedEntry(
                id: UUID(),
                label: label,
                entryType: .single(number),
                rawInput: phoneInput,
                createdAt: Date()
            )
            onSave(entry)
            dismiss()

        case .prefix:
            guard let (lo, hi) = VNPhoneParser.parsePrefix(prefixInput) else {
                errorMessage = "Đầu số không hợp lệ. Vui lòng nhập ít nhất 4 chữ số (VD: 0243 hoặc 02434)."
                return
            }
            let count = Int(hi - lo) + 1
            if count > 1_000_000 {
                errorMessage = "Dải số quá lớn (\(count.formatted()) số). Vui lòng nhập đầu số dài hơn để thu hẹp phạm vi."
                return
            }
            let entry = CustomBlockedEntry(
                id: UUID(),
                label: label,
                entryType: .prefix(lo, hi),
                rawInput: prefixInput,
                createdAt: Date()
            )
            onSave(entry)
            dismiss()
        }
    }
}

// MARK: - ViewModel

@MainActor
final class CustomBlockViewModel: ObservableObject {
    @Published var entries: [CustomBlockedEntry] = []
    @Published var status: ExtensionStatus = .checking
    @Published var isReloading = false
    @Published var feedbackMessage: String?
    @Published var feedbackIsError = false

    private let storage = CustomBlockedStorage.shared

    var extensionBundleID: String {
        let mainID = Bundle.main.bundleIdentifier ?? "com.vohoang.VNCallBlocker"
        return "\(mainID).BlockCustomExtension"
    }

    var totalCount: Int {
        entries.reduce(0) { $0 + $1.count }
    }

    func loadData() {
        entries = storage.loadEntries()
        Task { await checkStatus() }
    }

    func addEntry(_ entry: CustomBlockedEntry) {
        storage.addEntry(entry)
        entries = storage.loadEntries()
    }

    func removeEntry(id: UUID) {
        storage.removeEntry(id: id)
        entries = storage.loadEntries()
    }

    func checkStatus() async {
        status = .checking
        status = await withCheckedContinuation { continuation in
            CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionBundleID) { st, error in
                if error != nil {
                    continuation.resume(returning: .unknown)
                    return
                }
                switch st {
                case .enabled:  continuation.resume(returning: .enabled)
                case .disabled: continuation.resume(returning: .disabled)
                default:        continuation.resume(returning: .unknown)
                }
            }
        }
    }

    func reloadExtension() async {
        guard !isReloading else { return }
        isReloading = true
        feedbackMessage = nil
        do {
            try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
                CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionBundleID) { error in
                    if let error { c.resume(throwing: error) } else { c.resume(returning: ()) }
                }
            }
            feedbackIsError = false
            feedbackMessage = "Đã nạp \(totalCount.formatted()) số tùy chỉnh vào bộ lọc."
        } catch {
            feedbackIsError = true
            feedbackMessage = (error as NSError).localizedDescription
        }
        await checkStatus()
        isReloading = false
    }
}

import CallKit
