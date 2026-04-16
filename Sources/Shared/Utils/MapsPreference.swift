import Foundation

/// 地圖 App 偏好：讓用戶可以選擇預設開啟的地圖 App，
/// 或每次都詢問（符合 Apple Guideline 4 要求）。
///
/// 儲存在 `UserDefaults.standard`；主 App 和 Share Extension 若要共享，
/// 需設定 App Group 後改為 `UserDefaults(suiteName:)`。
/// 目前設計上兩邊各自獨立記憶偏好即可（用戶體驗上合理）。
enum MapsPreference: String, CaseIterable, Identifiable, Codable {
    /// 每次開啟地圖前詢問用戶
    case ask
    /// 一律使用 Apple 地圖
    case apple
    /// 一律使用 Google 地圖
    case google

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ask:    return String(localized: "每次詢問")
        case .apple:  return String(localized: "Apple 地圖")
        case .google: return String(localized: "Google 地圖")
        }
    }
}

/// 讀寫地圖偏好。這不是 ObservableObject，因為 `@AppStorage` 已能處理 SwiftUI 綁定。
enum MapsPreferenceStore {
    static let key = "pindrop.mapsPreference"

    static var current: MapsPreference {
        get {
            guard let raw = UserDefaults.standard.string(forKey: key),
                  let value = MapsPreference(rawValue: raw) else {
                return .ask
            }
            return value
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
        }
    }

    /// 對應到 `MapsApp`（.ask 回 nil）
    static var resolvedApp: MapsApp? {
        switch current {
        case .ask:    return nil
        case .apple:  return .apple
        case .google: return .google
        }
    }
}
