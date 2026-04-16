import Foundation

/// 支援的地圖 App 類型。
///
/// Apple 審查要求 (Guideline 4 — Design)：不可只開第三方地圖 App，
/// 必須提供 Apple Maps 作為選項。
enum MapsApp: String, CaseIterable, Identifiable, Codable {
    case apple
    case google

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple:  return String(localized: "Apple 地圖")
        case .google: return String(localized: "Google 地圖")
        }
    }

    var systemImage: String {
        switch self {
        case .apple:  return "map"
        case .google: return "map.fill"
        }
    }
}

enum MapsService {
    /// URL query-value 的安全字元集：以 .urlQueryAllowed 為基礎，
    /// 移除會破壞 query 結構的保留字元（&, =, +, ?, #），避免像
    /// "Bar & Grill" 的 & 被當成下一個 query parameter 的分隔符。
    private static let queryValueAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=+?#")
        return allowed
    }()

    private static func encode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: queryValueAllowed) ?? value
    }

    // MARK: - Google Maps

    /// comgooglemaps:// 直接開啟 Google Maps App（需已安裝）
    static func googleMapsAppURL(placeId: String, name: String = "") -> URL {
        let encodedName = encode(name)
        let encodedId = encode(placeId)
        return URL(string: "comgooglemaps://?q=\(encodedName)&query_place_id=\(encodedId)")!
    }

    /// Universal Link：未安裝 Google Maps 時 Safari 開啟網頁版
    static func googleMapsWebURL(placeId: String, name: String = "") -> URL {
        let encodedName = encode(name)
        let encodedId = encode(placeId)
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedName)&query_place_id=\(encodedId)")!
    }

    /// 主 App 使用（Universal Link，自動判斷是否安裝）
    static func googleMapsURL(placeId: String, name: String = "") -> URL {
        googleMapsWebURL(placeId: placeId, name: name)
    }

    // MARK: - Apple Maps

    /// Apple Maps universal link（https://maps.apple.com/）
    /// 只有 place name 可用時，用 `q` 搜尋字串帶入。
    /// 有 address 時一併帶入 `address` 幫助 Apple Maps 更精準命中。
    static func appleMapsWebURL(name: String, address: String = "") -> URL {
        let encodedName = encode(name)
        var urlString = "https://maps.apple.com/?q=\(encodedName)"
        if !address.isEmpty {
            urlString += "&address=\(encode(address))"
        }
        return URL(string: urlString)!
    }

    /// 給 Share Extension / 主 App 共用的 Apple Maps URL。
    /// universal link 會自動由系統路由到 Apple Maps App（不需額外 URL scheme 白名單）。
    static func appleMapsURL(name: String, address: String = "") -> URL {
        appleMapsWebURL(name: name, address: address)
    }

    // MARK: - 統一入口

    /// 根據選擇的地圖 App 回傳要開啟的 URL。
    /// 若 `.google` 但未安裝 Google Maps，呼叫端自行 fallback 到 `googleMapsWebURL`。
    static func url(for app: MapsApp, placeId: String, name: String, address: String = "") -> URL {
        switch app {
        case .apple:
            return appleMapsURL(name: name, address: address)
        case .google:
            return googleMapsURL(placeId: placeId, name: name)
        }
    }
}
