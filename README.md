# VNCallBlocker — Offline iOS CallKit Blocker for Vietnam VoIP & Spam (024 / 028)

An iOS utility application built with **Swift** and **SwiftUI** that leverages Apple's **CallKit** (`CXCallDirectoryProvider`) to block **1,800,000+ virtual PBX, VoIP, and telesales phone numbers** across Vietnam's two largest landline prefixes: **024 (Hanoi)** and **028 (Ho Chi Minh City)**.

---

## Key Features

- **100% Offline & Privacy-First (`CXCallDirectoryProvider`)**
  - Registers blocked E.164 phone number ranges directly into the iOS system call directory database.
  - Zero network permissions, zero background daemons, and zero access to incoming call logs or personal contacts.
- **Free Apple ID (Personal Team) Compatible**
  - Engineered without paid developer entitlements (`App Groups` not required).
  - Phone number ranges are compiled directly into the Call Directory Extensions, allowing any user to sign and sideload the app onto a physical iPhone using a free Apple ID.
- **Dual-Extension Architecture (`Block024Extension` & `Block028Extension`)**
  - Splits 1.8M+ numbers into two independent extensions to stay well within iOS Call Directory Extension memory limits (~50 MB JetSam limit).
  - Allows users to toggle blocking for Hanoi (`024`) and Ho Chi Minh City (`028`) independently in iOS Settings.
- **Dynamic Bundle Identifier Resolution**
  - Automatically derives extension identifiers (`<mainBundleID>.Block024Extension` and `<mainBundleID>.Block028Extension`) from `Bundle.main.bundleIdentifier`, simplifying custom code-signing setups.

---

## Blocked VoIP & Virtual PBX Ranges

All phone numbers follow CallKit's strict requirement: `Int64` (`CXCallDirectoryPhoneNumber`) formatted as `84` + area code (`24` or `28`) + 8-digit subscriber number, sorted in **strictly ascending order** without overlap.

### 1. `Block024Extension` — Hanoi (`024`)
| Prefix Format | E.164 Range (`Int64`) | Telecom / VoIP Operator | Total Numbers |
|---|---|---|---|
| `024 445x xxxx` | `842444500000...842444599999` | MobiFone / International VoIP | 100,000 |
| `024 567x xxxx` | `842456700000...842456799999` | VTC VoIP | 100,000 |
| `024 625x - 626x` | `842462500000...842462699999` | Viettel PBX (625-626) | 200,000 |
| `024 665x - 666x` | `842466500000...842466699999` | Viettel Wireless Fixed Line | 200,000 |
| `024 688x xxxx` | `842468800000...842468899999` | VoIP 688 | 100,000 |
| `024 710x xxxx` | `842471000000...842471099999` | CMC Telecom VoIP | 100,000 |
| `024 730x xxxx` | `842473000000...842473099999` | FPT Telecom VoIP | 100,000 |
| `024 777x xxxx` | `842477700000...842477799999` | Indochina Telecom VoIP | 100,000 |
| `024 858x xxxx` | `842485800000...842485899999` | Media / Virtual PBX | 100,000 |
| `024 888x xxxx` | `842488800000...842488899999` | Digitel VoIP | 100,000 |
| `024 999x xxxx` | `842499900000...842499999999` | Gtel Mobile / VoIP | 100,000 |

### 2. `Block028Extension` — Ho Chi Minh City (`028`)
| Prefix Format | E.164 Range (`Int64`) | Telecom / VoIP Operator | Total Numbers |
|---|---|---|---|
| `028 445x xxxx` | `842844500000...842844599999` | MobiFone / International VoIP | 100,000 |
| `028 567x xxxx` | `842856700000...842856799999` | VTC VoIP | 100,000 |
| `028 710x xxxx` | `842871000000...842871099999` | CMC Telecom VoIP | 100,000 |
| `028 730x xxxx` | `842873000000...842873099999` | FPT Telecom VoIP | 100,000 |
| `028 777x xxxx` | `842877700000...842877799999` | Indochina Telecom VoIP | 100,000 |
| `028 888x xxxx` | `842888800000...842888899999` | Digitel VoIP (incl. 028 8886 xxxx) | 100,000 |
| `028 999x xxxx` | `842899900000...842899999999` | Gtel Mobile / VoIP | 100,000 |

---

## Architecture & Tech Stack

```text
VNCallBlocker/
├── project.yml                         # XcodeGen specification for reproducible project generation
├── VNCallBlocker/
│   ├── VNCallBlockerApp.swift          # SwiftUI App entry point
│   ├── ContentView.swift               # Dashboard UI, status badges, and range inspector
│   ├── CallBlockerViewModel.swift      # Async CallKit status queries & extension reloading
│   └── Info.plist
├── Block024Extension/
│   ├── CallDirectoryHandler.swift      # CXCallDirectoryProvider for 024 (Hanoi)
│   └── Info.plist
└── Block028Extension/
    ├── CallDirectoryHandler.swift      # CXCallDirectoryProvider for 028 (HCMC)
    └── Info.plist
```

- **Language:** Swift 5.9+ (Strict Concurrency with `@MainActor` & `async/await`)
- **Frameworks:** SwiftUI, CallKit (`CXCallDirectoryProvider`, `CXCallDirectoryManager`)
- **Build Tooling:** XcodeGen (`project.yml`), `xcodebuild`

---

## Getting Started

### 1. Clone & Open Project
```bash
git clone https://github.com/VoHoang07/VNCallBlocker.git
cd VNCallBlocker
open VNCallBlocker.xcodeproj
```
*(Optional: If you modify `project.yml`, run `xcodegen generate` to regenerate `VNCallBlocker.xcodeproj`.)*

### 2. Code Signing (Personal Team)
1. In Xcode, open **Signing & Capabilities**.
2. Select your **Personal Team** (free Apple ID) for all 3 targets: `VNCallBlocker`, `Block024Extension`, and `Block028Extension`.
3. If you change the base Bundle Identifier (e.g., `com.yourname.VNCallBlocker`), ensure the two extensions use the matching prefix (`com.yourname.VNCallBlocker.Block024Extension` and `com.yourname.VNCallBlocker.Block028Extension`).

### 3. Activate on iPhone
1. Build and run the app on a physical iPhone (**Cmd + R**).
2. Open **Settings > Apps > Phone > Call Blocking & Identification** (or tap **"Mở nhanh Cài đặt"** inside the app).
3. Enable both **VNCallBlocker - Đầu 024 (HN)** and **VNCallBlocker - Đầu 028 (HCM)**.
4. Return to the app and tap **Cập nhật tất cả (024 & 028)** to verify active protection.
