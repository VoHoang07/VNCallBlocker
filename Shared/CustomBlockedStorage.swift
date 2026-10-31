import Foundation
import CallKit

// MARK: - App Group Constants

/// App Group identifier dùng chung giữa App chính và BlockCustomExtension.
/// Khi đổi Bundle ID trong Xcode, cần đổi App Group ID tương ứng trong Signing & Capabilities.
enum AppGroupConstants {
    static let suiteName = "group.com.vohoang.VNCallBlocker"
    static let customNumbersKey = "custom_blocked_numbers"
}

// MARK: - Custom Blocked Entry Model

/// Một mục chặn tùy chỉnh do người dùng nhập.
/// - `single`: Chặn 1 số điện thoại cụ thể (VD: 02412345678)
/// - `prefix`: Chặn toàn bộ dải số theo prefix (VD: prefix "02434" → 0243400000...0243499999)
struct CustomBlockedEntry: Codable, Identifiable, Equatable {
    let id: UUID
    let label: String          // Nhãn ghi chú do người dùng đặt
    let entryType: EntryType
    let rawInput: String       // Chuỗi gốc người dùng nhập (hiển thị lại trên UI)
    let createdAt: Date

    enum EntryType: Codable, Equatable {
        case single(Int64)                    // 1 số E.164
        case prefix(Int64, Int64)             // (lowerBound, upperBound) dải số E.164
    }

    /// Tổng số điện thoại mà entry này chặn
    var count: Int {
        switch entryType {
        case .single:
            return 1
        case .prefix(let lo, let hi):
            return Int(hi - lo) + 1
        }
    }

    /// Mô tả ngắn gọn cho UI
    var subtitle: String {
        switch entryType {
        case .single(let num):
            return "Số \(Self.formatE164(num))"
        case .prefix(let lo, let hi):
            return "\(Self.formatE164(lo)) → \(Self.formatE164(hi)) (\(count.formatted()) số)"
        }
    }

    private static func formatE164(_ num: Int64) -> String {
        return "+\(num)"
    }
}

// MARK: - Shared Storage

/// Đọc/ghi danh sách số chặn tùy chỉnh qua App Group UserDefaults.
/// Dùng chung cho cả App chính (ghi) và BlockCustomExtension (đọc).
final class CustomBlockedStorage {

    static let shared = CustomBlockedStorage()

    private let defaults: UserDefaults?

    private init() {
        self.defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    /// Đọc toàn bộ danh sách entries
    func loadEntries() -> [CustomBlockedEntry] {
        guard let defaults,
              let data = defaults.data(forKey: AppGroupConstants.customNumbersKey) else {
            return []
        }
        return (try? JSONDecoder().decode([CustomBlockedEntry].self, from: data)) ?? []
    }

    /// Ghi toàn bộ danh sách entries
    func saveEntries(_ entries: [CustomBlockedEntry]) {
        guard let defaults,
              let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: AppGroupConstants.customNumbersKey)
        defaults.synchronize()
    }

    /// Thêm 1 entry mới
    func addEntry(_ entry: CustomBlockedEntry) {
        var entries = loadEntries()
        entries.append(entry)
        saveEntries(entries)
    }

    /// Xóa entry theo ID
    func removeEntry(id: UUID) {
        var entries = loadEntries()
        entries.removeAll { $0.id == id }
        saveEntries(entries)
    }

    /// Trả về danh sách tất cả số Int64 (đã sorted, deduplicated) để nạp vào CallKit
    func allBlockedPhoneNumbers() -> [Int64] {
        let entries = loadEntries()
        var numbers = Set<Int64>()
        for entry in entries {
            switch entry.entryType {
            case .single(let num):
                numbers.insert(num)
            case .prefix(let lo, let hi):
                for n in lo...hi {
                    numbers.insert(n)
                }
            }
        }
        return numbers.sorted()
    }
}

// MARK: - Phone Number Parser

/// Chuyển đổi chuỗi số điện thoại Việt Nam thành E.164 Int64 (84xxxxxxxxx).
enum VNPhoneParser {

    /// Parse 1 số điện thoại cố định VN → E.164 Int64
    /// Hỗ trợ: "02412345678", "+842412345678", "842412345678", "024 1234 5678"
    static func parseSingle(_ input: String) -> Int64? {
        let cleaned = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard !cleaned.isEmpty else { return nil }

        var digits = cleaned

        // +84... hoặc 84... (11+ chữ số bắt đầu bằng 84)
        if digits.hasPrefix("84") && digits.count >= 11 {
            // OK — already E.164 without +
        }
        // 0xx... (bắt đầu bằng 0, cố định 10-11 chữ số)
        else if digits.hasPrefix("0") && digits.count >= 10 {
            digits = "84" + digits.dropFirst() // bỏ số 0, thêm 84
        }
        else {
            return nil
        }

        guard let number = Int64(digits) else { return nil }

        // Validate: phải nằm trong khoảng hợp lý cho VN (842xxxxxxxxx)
        guard number >= 84_200_000_0000 && number <= 84_999_999_9999 else { return nil }
        return number
    }

    /// Parse prefix đầu số VN → (lowerBound, upperBound) E.164 Int64
    /// Input: "0243", "02434", "024345", "0243456", "02434567"
    /// Kết quả: pad thêm 0 đến đủ 11 chữ số E.164 (84 + 9 digits) để tạo range
    static func parsePrefix(_ input: String) -> (Int64, Int64)? {
        let cleaned = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard !cleaned.isEmpty else { return nil }

        var digits = cleaned

        // Chuẩn hóa thành dạng 84...
        if digits.hasPrefix("84") {
            // OK
        } else if digits.hasPrefix("0") {
            digits = "84" + digits.dropFirst()
        } else {
            return nil
        }

        // Số E.164 VN cố định: 84 + 2 (mã vùng) + 8 (thuê bao) = 12 chữ số tổng cộng
        let targetLength = 12
        guard digits.count >= 4 && digits.count <= targetLength else { return nil }

        let padCount = targetLength - digits.count
        let loStr = digits + String(repeating: "0", count: padCount)
        let hiStr = digits + String(repeating: "9", count: padCount)

        guard let lo = Int64(loStr), let hi = Int64(hiStr) else { return nil }
        guard lo >= 84_200_000_0000 && hi <= 84_999_999_9999 else { return nil }

        return (lo, hi)
    }
}
