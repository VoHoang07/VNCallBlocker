# VNCallBlocker

Ứng dụng iOS (Swift & SwiftUI) sử dụng `CallKit` (`CXCallDirectoryProvider`) để chặn toàn bộ các dải số tổng đài ảo (VoIP / Telesales / Spam) đầu số **024 (Hà Nội)** và **028 (TP.HCM)**.

## Đặc điểm nổi bật
- **Không cần App Groups / Paid Developer Account:** Có thể ký (sign) và cài trực tiếp lên iPhone thật bằng tài khoản Apple ID miễn phí (Personal Team).
- **Tách riêng 2 Call Directory Extension:**
  - `Block024Extension`: Chặn 11 dải số VoIP đầu `024` (Hà Nội).
  - `Block028Extension`: Chặn 7 dải số VoIP đầu `028` (TP.HCM).
- **Hoạt động 100% Offline:** Tuân thủ nghiêm ngặt quy tắc `CXCallDirectoryProvider` của Apple.

## Cách cài đặt
1. Mở `VNCallBlocker.xcodeproj` bằng Xcode (hoặc chạy `xcodegen generate` từ `project.yml`).
2. Vào **Signing & Capabilities**, chọn **Team** (Personal Team) và đổi Bundle Identifier gốc nếu cần (giữ hậu tố `.Block024Extension` và `.Block028Extension` cho 2 Extension).
3. Build & Run lên iPhone thật.
4. Trên iPhone, vào **Cài đặt > Ứng dụng > Điện thoại > Chặn cuộc gọi & Nhận dạng** để bật quyền cho cả 2 bộ lọc `024` và `028`.
