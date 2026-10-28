import Foundation
import CallKit

final class CallDirectoryHandler: CXCallDirectoryProvider {

    /// Danh sách các dải số tổng đài ảo / VoIP / Telesales đầu 024 (Hà Nội)
    /// Quy tắc CallKit: Định dạng 84 + 24 + 8 chữ số, sắp xếp tăng dần tuyệt đối (strictly ascending) và không chồng lấn.
    private static let blockedRanges024: [ClosedRange<CXCallDirectoryPhoneNumber>] = [
        842444500000...842444599999, // VoIP MobiFone / Quốc tế (100.000 số)
        842456700000...842456799999, // VoIP VTC (100.000 số)
        842462500000...842462699999, // Tổng đài Viettel nhánh 625-626 (200.000 số)
        842466500000...842466699999, // Cố định không dây Viettel nhánh 665-666 (200.000 số)
        842468800000...842468899999, // VoIP mới 688 (100.000 số)
        842471000000...842471099999, // VoIP CMC (100.000 số)
        842473000000...842473099999, // VoIP FPT (100.000 số)
        842477700000...842477799999, // VoIP Indochina Telecom (100.000 số)
        842485800000...842485899999, // VoIP Truyền thông (100.000 số)
        842488800000...842488899999, // VoIP Digitel (100.000 số)
        842499900000...842499999999  // VoIP Gtel (100.000 số)
    ]

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        if context.isIncremental {
            context.removeAllBlockingEntries()
        }

        addAllBlockingPhoneNumbers(to: context)
        context.completeRequest()
    }

    private func addAllBlockingPhoneNumbers(to context: CXCallDirectoryExtensionContext) {
        for range in Self.blockedRanges024 {
            for phoneNumber in range {
                context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
            }
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        NSLog("[Block024Extension] Request failed with error: \(error.localizedDescription)")
    }
}
