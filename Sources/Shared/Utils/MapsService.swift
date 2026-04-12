import Foundation

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
}
