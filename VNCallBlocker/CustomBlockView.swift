import SwiftUI
import CallKit

struct CustomBlockView: View {
    @StateObject private var viewModel = CustomBlockViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Số tùy chỉnh")
                        .font(.title3.weight(.bold))
                    Text("\(CustomNumbers.entries.count) mục • \(CustomNumbers.totalCount.formatted()) số")
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

            // Reload button
            Button {
                Task { await viewModel.reloadExtension() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isReloading {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(viewModel.isReloading ? "Đang nạp bộ lọc..." : "Reload / Cập nhật bộ lọc")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.accentColor.opacity(0.14))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(viewModel.isReloading)

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

            // Entries list or empty state
            if CustomNumbers.entries.isEmpty {
                instructionCard
            } else {
                DisclosureGroup("Danh sách \(CustomNumbers.entries.count) mục đang chặn") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(CustomNumbers.entries.enumerated()), id: \.offset) { _, entry in
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.label)
                                        .font(.caption.weight(.semibold))
                                    Text(entry.subtitle)
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.top, 6)
                }
                .font(.footnote.weight(.medium))

                instructionCard
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            Task { await viewModel.checkStatus() }
        }
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Cách thêm số chặn tùy chỉnh", systemImage: "doc.text")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 4) {
                instructionRow("1", "Mở file Shared/CustomNumbers.swift trong Xcode")
                instructionRow("2", "Thêm số vào mảng entries (xem hướng dẫn trong file)")
                instructionRow("3", "Build lại App (⌘R) → Cài lên iPhone")
                instructionRow("4", "Nhấn \"Cập nhật\" ở trên để nạp số mới vào iOS")
            }

            Text("Ví dụ cú pháp:")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            Text("""
            .single(842412345678, label: "Spam XYZ")
            .range(842434500000...842434599999, label: "VoIP 024 345x")
            """)
            .font(.caption2.monospaced())
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .padding(10)
        .background(Color.purple.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func instructionRow(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(number)
                .font(.caption2.weight(.bold))
                .frame(width: 16, height: 16)
                .background(Color.purple.opacity(0.15))
                .foregroundStyle(.purple)
                .clipShape(Circle())
            Text(text)
                .font(.caption2)
                .foregroundStyle(.primary)
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

// MARK: - ViewModel

@MainActor
final class CustomBlockViewModel: ObservableObject {
    @Published var status: ExtensionStatus = .checking
    @Published var isReloading = false
    @Published var feedbackMessage: String?
    @Published var feedbackIsError = false

    var extensionBundleID: String {
        let mainID = Bundle.main.bundleIdentifier ?? "com.vohoang.VNCallBlocker"
        return "\(mainID).BlockCustomExtension"
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
            feedbackMessage = "Đã nạp \(CustomNumbers.totalCount.formatted()) số tùy chỉnh vào bộ lọc."
        } catch {
            feedbackIsError = true
            feedbackMessage = (error as NSError).localizedDescription
        }
        await checkStatus()
        isReloading = false
    }
}
