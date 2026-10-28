import Foundation
import CallKit
import UIKit

struct BlockedRangeInfo: Identifiable {
    let id = UUID()
    let displayPrefix: String
    let rangeString: String
    let providerDescription: String
    let count: Int
}

enum ExtensionStatus: Equatable {
    case checking
    case enabled
    case disabled
    case unknown
    case error(String)

    var title: String {
        switch self {
        case .checking:
            return "Đang kiểm tra..."
        case .enabled:
            return "Đã bật (Đang bảo vệ)"
        case .disabled:
            return "Chưa bật trong Cài đặt"
        case .unknown:
            return "Không xác định"
        case .error(let message):
            return "Lỗi: \(message)"
        }
    }

    var isEnabled: Bool {
        if case .enabled = self { return true }
        return false
    }
}

@MainActor
final class CallBlockerViewModel: ObservableObject {
    @Published var status024: ExtensionStatus = .checking
    @Published var status028: ExtensionStatus = .checking

    @Published var isReloading024: Bool = false
    @Published var isReloading028: Bool = false
    @Published var isReloadingAll: Bool = false

    @Published var feedbackMessage024: String?
    @Published var feedbackIsError024: Bool = false

    @Published var feedbackMessage028: String?
    @Published var feedbackIsError028: Bool = false

    @Published var globalBannerMessage: String?
    @Published var globalBannerIsError: Bool = false

    /// Tự động lấy Bundle ID gốc của App chính để ghép thành Bundle ID của 2 Extension
    var mainBundleID: String {
        Bundle.main.bundleIdentifier ?? "com.vohoang.VNCallBlocker"
    }

    var extension024BundleID: String {
        "\(mainBundleID).Block024Extension"
    }

    var extension028BundleID: String {
        "\(mainBundleID).Block028Extension"
    }

    let ranges024: [BlockedRangeInfo] = [
        BlockedRangeInfo(displayPrefix: "024 445x xxxx", rangeString: "842444500000...842444599999", providerDescription: "VoIP MobiFone / Quốc tế", count: 100_000),
        BlockedRangeInfo(displayPrefix: "024 567x xxxx", rangeString: "842456700000...842456799999", providerDescription: "VoIP VTC", count: 100_000),
        BlockedRangeInfo(displayPrefix: "024 625x - 626x", rangeString: "842462500000...842462699999", providerDescription: "Tổng đài Viettel nhánh 625-626", count: 200_000),
        BlockedRangeInfo(displayPrefix: "024 665x - 666x", rangeString: "842466500000...842466699999", providerDescription: "Cố định không dây Viettel 665-666", count: 200_000),
        BlockedRangeInfo(displayPrefix: "024 688x xxxx", rangeString: "842468800000...842468899999", providerDescription: "VoIP mới 688", count: 100_000),
        BlockedRangeInfo(displayPrefix: "024 710x xxxx", rangeString: "842471000000...842471099999", providerDescription: "VoIP CMC", count: 100_000),
        BlockedRangeInfo(displayPrefix: "024 730x xxxx", rangeString: "842473000000...842473099999", providerDescription: "VoIP FPT", count: 100_000),
        BlockedRangeInfo(displayPrefix: "024 777x xxxx", rangeString: "842477700000...842477799999", providerDescription: "VoIP Indochina Telecom", count: 100_000),
        BlockedRangeInfo(displayPrefix: "024 858x xxxx", rangeString: "842485800000...842485899999", providerDescription: "VoIP Truyền thông", count: 100_000),
        BlockedRangeInfo(displayPrefix: "024 888x xxxx", rangeString: "842488800000...842488899999", providerDescription: "VoIP Digitel", count: 100_000),
        BlockedRangeInfo(displayPrefix: "024 999x xxxx", rangeString: "842499900000...842499999999", providerDescription: "VoIP Gtel", count: 100_000)
    ]

    let ranges028: [BlockedRangeInfo] = [
        BlockedRangeInfo(displayPrefix: "028 445x xxxx", rangeString: "842844500000...842844599999", providerDescription: "VoIP MobiFone / Quốc tế", count: 100_000),
        BlockedRangeInfo(displayPrefix: "028 567x xxxx", rangeString: "842856700000...842856799999", providerDescription: "VoIP VTC", count: 100_000),
        BlockedRangeInfo(displayPrefix: "028 710x xxxx", rangeString: "842871000000...842871099999", providerDescription: "VoIP CMC", count: 100_000),
        BlockedRangeInfo(displayPrefix: "028 730x xxxx", rangeString: "842873000000...842873099999", providerDescription: "VoIP FPT", count: 100_000),
        BlockedRangeInfo(displayPrefix: "028 777x xxxx", rangeString: "842877700000...842877799999", providerDescription: "VoIP Indochina Telecom", count: 100_000),
        BlockedRangeInfo(displayPrefix: "028 888x xxxx", rangeString: "842888800000...842888899999", providerDescription: "VoIP Digitel (gồm 028 8886 xxxx)", count: 100_000),
        BlockedRangeInfo(displayPrefix: "028 999x xxxx", rangeString: "842899900000...842899999999", providerDescription: "VoIP Gtel", count: 100_000)
    ]

    func refreshAllStatuses() {
        Task {
            await checkStatus024()
            await checkStatus028()
        }
    }

    func checkStatus024() async {
        status024 = .checking
        status024 = await fetchEnabledStatus(for: extension024BundleID)
    }

    func checkStatus028() async {
        status028 = .checking
        status028 = await fetchEnabledStatus(for: extension028BundleID)
    }

    func reload024() async {
        guard !isReloading024 else { return }
        isReloading024 = true
        feedbackMessage024 = nil
        do {
            try await reloadExtension(identifier: extension024BundleID)
            feedbackIsError024 = false
            feedbackMessage024 = "Đã nạp thành công 11 dải số đầu 024 (Hà Nội)."
        } catch {
            feedbackIsError024 = true
            feedbackMessage024 = Self.friendlyErrorMessage(from: error)
        }
        await checkStatus024()
        isReloading024 = false
    }

    func reload028() async {
        guard !isReloading028 else { return }
        isReloading028 = true
        feedbackMessage028 = nil
        do {
            try await reloadExtension(identifier: extension028BundleID)
            feedbackIsError028 = false
            feedbackMessage028 = "Đã nạp thành công 7 dải số đầu 028 (TP.HCM)."
        } catch {
            feedbackIsError028 = true
            feedbackMessage028 = Self.friendlyErrorMessage(from: error)
        }
        await checkStatus028()
        isReloading028 = false
    }

    func reloadAll() async {
        guard !isReloadingAll else { return }
        isReloadingAll = true
        globalBannerMessage = nil

        await reload024()
        await reload028()

        if !feedbackIsError024 && !feedbackIsError028 {
            globalBannerIsError = false
            globalBannerMessage = "Đã cập nhật thành công toàn bộ bộ lọc đầu 024 & 028!"
        } else {
            globalBannerIsError = true
            globalBannerMessage = "Một hoặc cả hai bộ lọc chưa thể nạp. Hãy kiểm tra quyền trong Cài đặt."
        }
        isReloadingAll = false
    }

    func openSystemSettings() {
        CXCallDirectoryManager.sharedInstance.openSettings { error in
            if error != nil {
                Task { @MainActor in
                    guard let url = URL(string: UIApplication.openSettingsURLString),
                          UIApplication.shared.canOpenURL(url) else { return }
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    private func fetchEnabledStatus(for identifier: String) async -> ExtensionStatus {
        await withCheckedContinuation { continuation in
            CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: identifier) { status, error in
                if let error = error {
                    continuation.resume(returning: .error(Self.friendlyErrorMessage(from: error)))
                    return
                }
                switch status {
                case .enabled:
                    continuation.resume(returning: .enabled)
                case .disabled:
                    continuation.resume(returning: .disabled)
                case .unknown:
                    continuation.resume(returning: .unknown)
                @unknown default:
                    continuation.resume(returning: .unknown)
                }
            }
        }
    }

    private func reloadExtension(identifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: identifier) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    nonisolated private static func friendlyErrorMessage(from error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == CXErrorDomainCallDirectoryManager,
           let code = CXErrorCodeCallDirectoryManagerError.Code(rawValue: nsError.code) {
            switch code {
            case .noExtensionFound:
                return "Không tìm thấy Extension (Kiểm tra Bundle ID / chạy trên thiết bị thật)."
            case .loadingInterrupted:
                return "Quá trình nạp danh sách số bị gián đoạn. Vui lòng thử lại."
            case .entriesOutOfOrder:
                return "Danh sách số không theo thứ tự tăng dần."
            case .duplicateEntries:
                return "Danh sách có số bị trùng lặp."
            case .maximumEntriesExceeded:
                return "Vượt quá số lượng tối đa của hệ thống."
            case .extensionDisabled:
                return "Extension chưa được bật trong Cài đặt > Điện thoại > Chặn cuộc gọi & Nhận dạng."
            case .currentlyLoading:
                return "Hệ thống đang xử lý nạp dữ liệu, vui lòng đợi giây lát."
            case .unexpectedIncrementalRemoval:
                return "Lỗi xóa dữ liệu incremental không mong đợi."
            case .unknown:
                return "Lỗi CallKit không xác định (Simulator không hỗ trợ CallKit đầy đủ)."
            @unknown default:
                return nsError.localizedDescription
            }
        }
        return nsError.localizedDescription
    }
}
