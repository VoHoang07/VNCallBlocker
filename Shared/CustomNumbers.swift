import Foundation
import CallKit

// =====================================================================
// HƯỚNG DẪN THÊM SỐ CHẶN TÙY CHỈNH
// =====================================================================
//
// File này là nguồn dữ liệu DUY NHẤT cho Extension "Số tùy chỉnh".
// Nó được biên dịch vào CẢ App chính (hiển thị) và BlockCustomExtension
// (nạp vào CallKit), nên KHÔNG cần App Groups hay Paid Entitlements.
//
// CÁCH THÊM SỐ:
//
// 1. Thêm 1 số cụ thể (E.164, bắt đầu bằng 84):
//      .single(842412345678, label: "Tổng đài spam XYZ")
//
// 2. Thêm cả dải đầu số (tất cả số bắt đầu bằng prefix đó):
//      .range(842434500000...842434599999, label: "VoIP đầu 024 345x")
//
// QUY TẮC:
// - Định dạng E.164: 84 + mã vùng bỏ số 0 (24/28/...) + 8 chữ số thuê bao
//   VD: 024 1234 5678 → 842412345678
// - Các entry PHẢI được sắp xếp TĂNG DẦN theo số đầu tiên
// - Các dải KHÔNG ĐƯỢC chồng lấn nhau
// - Sau khi sửa file này: Build lại App → Cài lên iPhone → Nhấn "Cập nhật"
//
// =====================================================================

/// Danh sách số chặn tùy chỉnh, dùng chung cho App chính và BlockCustomExtension.
enum CustomNumbers {

    /// Các mục chặn tùy chỉnh. Sắp xếp tăng dần, không chồng lấn.
    static let entries: [Entry] = [
        // ── Thêm số chặn tùy chỉnh của bạn vào đây ──
        //
        // Ví dụ (bỏ dấu // để kích hoạt):
        //
        // .single(842412345678, label: "Số spam hay gọi"),
        // .range(842434500000...842434599999, label: "VoIP đầu 024 345x xxxx"),
        // .range(842838000000...842838099999, label: "VoIP đầu 028 380x xxxx"),
    ]

    // MARK: - Entry Type

    enum Entry {
        /// Chặn 1 số điện thoại cụ thể
        case single(CXCallDirectoryPhoneNumber, label: String)
        /// Chặn toàn bộ dải số
        case range(ClosedRange<CXCallDirectoryPhoneNumber>, label: String)

        var label: String {
            switch self {
            case .single(_, let l): return l
            case .range(_, let l):  return l
            }
        }

        var count: Int {
            switch self {
            case .single: return 1
            case .range(let r, _): return r.count
            }
        }

        /// Mô tả ngắn cho UI
        var subtitle: String {
            switch self {
            case .single(let n, _):
                return "+\(n)"
            case .range(let r, _):
                return "+\(r.lowerBound)...+\(r.upperBound) (\(r.count.formatted()) số)"
            }
        }

        /// Số đầu tiên (dùng để sắp xếp)
        var firstNumber: CXCallDirectoryPhoneNumber {
            switch self {
            case .single(let n, _): return n
            case .range(let r, _):  return r.lowerBound
            }
        }
    }

    // MARK: - Helpers

    /// Tổng số điện thoại bị chặn
    static var totalCount: Int {
        entries.reduce(0) { $0 + $1.count }
    }

    /// Nạp toàn bộ số vào CallKit context (đã sorted, strictly ascending)
    static func addAllEntries(to context: CXCallDirectoryExtensionContext) {
        for entry in entries {
            switch entry {
            case .single(let number, _):
                context.addBlockingEntry(withNextSequentialPhoneNumber: number)
            case .range(let range, _):
                for number in range {
                    context.addBlockingEntry(withNextSequentialPhoneNumber: number)
                }
            }
        }
    }
}
