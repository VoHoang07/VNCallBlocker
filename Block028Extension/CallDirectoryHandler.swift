import Foundation
import CallKit

final class CallDirectoryHandler: CXCallDirectoryProvider {

    /// Danh sách các dải số tổng đài ảo / VoIP / Telesales đầu 028 (TP.HCM)
    /// Quy tắc CallKit: Định dạng 84 + 28 + 8 chữ số, sắp xếp tăng dần tuyệt đối (strictly ascending) và không chồng lấn.
    private static let blockedRanges028: [ClosedRange<CXCallDirectoryPhoneNumber>] = [
        842844500000...842844599999, // VoIP MobiFone / Quốc tế (100.000 số)
        842856700000...842856799999, // VoIP VTC (100.000 số)
        842871000000...842871099999, // VoIP CMC (100.000 số)
        842873000000...842873099999, // VoIP FPT (100.000 số)
        842877700000...842877799999, // VoIP Indochina Telecom (100.000 số)
        842888800000...842888899999, // VoIP Digitel - bao gồm nhánh 028 8886 xxxx (100.000 số)
        842899900000...842899999999  // VoIP Gtel (100.000 số)
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
        for range in Self.blockedRanges028 {
            for phoneNumber in range {
                context.addBlockingEntry(withNextSequentialPhoneNumber: phoneNumber)
            }
        }
    }
}

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        NSLog("[Block028Extension] Request failed with error: \(error.localizedDescription)")
    }
}
