import SwiftUI
import UIKit

/// 集中處理「點『地圖』→ 依偏好決定是否詢問 → 開對應 App」的邏輯。
///
/// 兩種使用方式：
/// 1. 主 App：直接呼叫 `MapsLauncher.open(...)`，它會讀取 `MapsPreferenceStore`，
///    若為 `.ask` 則透過 `.mapsPicker(...)` modifier 呈現 confirmationDialog。
/// 2. Share Extension：無法使用 `UIApplication.shared.open`，由呼叫端傳入 `openURL` closure。
struct MapsTarget: Equatable {
    let placeId: String
    let name: String
    let address: String

    init(placeId: String, name: String, address: String = "") {
        self.placeId = placeId
        self.name = name
        self.address = address
    }
}

// MARK: - Picker modifier

extension View {
    /// 在當前 View 上掛上「選擇地圖 App」的 confirmationDialog。
    ///
    /// - Parameters:
    ///   - target: 綁定的目標餐廳；非 nil 時顯示 dialog。
    ///   - onSelect: 用戶選定後的 callback，呼叫端負責實際開啟 URL。
    func mapsPicker(
        target: Binding<MapsTarget?>,
        onSelect: @escaping (MapsApp, MapsTarget) -> Void
    ) -> some View {
        self.confirmationDialog(
            String(localized: "選擇地圖 App"),
            isPresented: Binding(
                get: { target.wrappedValue != nil },
                set: { if !$0 { target.wrappedValue = nil } }
            ),
            titleVisibility: .visible,
            presenting: target.wrappedValue
        ) { current in
            Button(MapsApp.apple.displayName) {
                onSelect(.apple, current)
            }
            Button(MapsApp.google.displayName) {
                onSelect(.google, current)
            }
            Button(String(localized: "取消"), role: .cancel) {}
        } message: { current in
            Text(current.name)
        }
    }
}

// MARK: - 主 App launcher（使用 UIApplication.shared）

enum MapsLauncher {
    /// 依偏好決定：若使用者已設定，直接開；若 `.ask`，將 `target` 寫入 binding 由 UI 呈現 picker。
    @MainActor
    static func requestOpen(
        _ target: MapsTarget,
        pickerTarget: Binding<MapsTarget?>
    ) {
        if let app = MapsPreferenceStore.resolvedApp {
            openImmediately(target, with: app)
        } else {
            pickerTarget.wrappedValue = target
        }
    }

    /// 已決定要用哪個地圖 App，直接開啟。
    @MainActor
    static func openImmediately(_ target: MapsTarget, with app: MapsApp) {
        let url = MapsService.url(
            for: app,
            placeId: target.placeId,
            name: target.name,
            address: target.address
        )
        UIApplication.shared.open(url) { success in
            // Google Maps universal link 即使沒裝 Google Maps 也會由 Safari 開網頁版，
            // 所以不需要額外 fallback。Apple Maps universal link 一定開得起來。
            if !success {
                print("[Pindrop] Failed to open \(url)")
            }
        }
    }
}
