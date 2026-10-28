import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CallBlockerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    headerBanner
                    settingsGuideCard
                    reloadAllButton
                    extensionCard(
                        title: "Đầu số 024 (Hà Nội)",
                        subtitle: "11 dải VoIP/Telesales • 1.100.000+ số",
                        bundleID: viewModel.extension024BundleID,
                        status: viewModel.status024,
                        isReloading: viewModel.isReloading024,
                        feedbackMessage: viewModel.feedbackMessage024,
                        feedbackIsError: viewModel.feedbackIsError024,
                        ranges: viewModel.ranges024,
                        reloadAction: {
                            Task { await viewModel.reload024() }
                        }
                    )
                    extensionCard(
                        title: "Đầu số 028 (TP.HCM)",
                        subtitle: "7 dải VoIP/Telesales • 700.000 số",
                        bundleID: viewModel.extension028BundleID,
                        status: viewModel.status028,
                        isReloading: viewModel.isReloading028,
                        feedbackMessage: viewModel.feedbackMessage028,
                        feedbackIsError: viewModel.feedbackIsError028,
                        ranges: viewModel.ranges028,
                        reloadAction: {
                            Task { await viewModel.reload028() }
                        }
                    )
                    bundleIDFooter
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("VNCallBlocker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.refreshAllStatuses()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isReloading024 || viewModel.isReloading028 || viewModel.isReloadingAll)
                }
            }
            .onAppear {
                viewModel.refreshAllStatuses()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.refreshAllStatuses()
                }
            }
        }
    }

    private var headerBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "phone.down.waves.left.and.right")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Chặn Tổng Đài Ảo 024 & 028")
                    .font(.headline)
                Text("Hoạt động offline 100% qua CallKit • Không cần App Groups")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var settingsGuideCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Hướng dẫn kích hoạt quyền chặn", systemImage: "gear.badge.checkmark")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.blue)

            Text("Vào Cài đặt > Ứng dụng > Điện thoại > Chặn cuộc gọi & Nhận dạng để bật quyền")
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                viewModel.openSystemSettings()
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Mở nhanh Cài đặt")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Color.blue.opacity(0.12))
                .foregroundStyle(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var reloadAllButton: some View {
        VStack(spacing: 10) {
            Button {
                Task { await viewModel.reloadAll() }
            } label: {
                HStack(spacing: 10) {
                    if viewModel.isReloadingAll || viewModel.isReloading024 || viewModel.isReloading028 {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    }
                    Text(
                        (viewModel.isReloadingAll || viewModel.isReloading024 || viewModel.isReloading028)
                        ? "Đang nạp danh sách số vào iOS..."
                        : "Cập nhật tất cả (024 & 028)"
                    )
                    .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    (viewModel.isReloadingAll || viewModel.isReloading024 || viewModel.isReloading028)
                    ? Color.gray
                    : Color.accentColor
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(viewModel.isReloadingAll || viewModel.isReloading024 || viewModel.isReloading028)

            if let globalMessage = viewModel.globalBannerMessage {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.globalBannerIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    Text(globalMessage)
                        .font(.footnote)
                }
                .foregroundStyle(viewModel.globalBannerIsError ? .red : .green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background((viewModel.globalBannerIsError ? Color.red : Color.green).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func extensionCard(
        title: String,
        subtitle: String,
        bundleID: String,
        status: ExtensionStatus,
        isReloading: Bool,
        feedbackMessage: String?,
        feedbackIsError: Bool,
        ranges: [BlockedRangeInfo],
        reloadAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.bold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusBadge(for: status)
            }

            Divider()

            HStack {
                Image(systemName: status.isEnabled ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundStyle(status.isEnabled ? .green : .orange)
                Text(status.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(status.isEnabled ? .green : .primary)
                Spacer()
            }

            Button(action: reloadAction) {
                HStack(spacing: 8) {
                    if isReloading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.triangle.2.circlepath")
                    }
                    Text(isReloading ? "Đang nạp bộ lọc..." : "Reload / Cập nhật bộ lọc")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(Color.accentColor.opacity(0.14))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(isReloading || viewModel.isReloadingAll)

            if let feedbackMessage {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: feedbackIsError ? "xmark.octagon.fill" : "checkmark.circle.fill")
                    Text(feedbackMessage)
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(feedbackIsError ? .red : .green)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background((feedbackIsError ? Color.red : Color.green).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            DisclosureGroup("Danh sách \(ranges.count) dải số bị chặn") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ranges) { item in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayPrefix)
                                    .font(.caption.monospaced().weight(.semibold))
                                Text(item.providerDescription)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(item.rangeString)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.top, 6)
            }
            .font(.footnote.weight(.medium))
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func statusBadge(for status: ExtensionStatus) -> some View {
        switch status {
        case .checking:
            ProgressView()
                .controlSize(.small)
        case .enabled:
            Text("BẬT")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.18))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        case .disabled:
            Text("TẮT")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.18))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        case .unknown, .error:
            Text("LỖI / CHƯA RÕ")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.15))
                .foregroundStyle(.red)
                .clipShape(Capsule())
        }
    }

    private var bundleIDFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Cấu hình Bundle Identifier tự động:")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("• App: \(viewModel.mainBundleID)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
            Text("• 024: \(viewModel.extension024BundleID)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
            Text("• 028: \(viewModel.extension028BundleID)")
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }
}

#Preview {
    ContentView()
}
