import Foundation

enum MapsService {
    /// comgooglemaps:// 直接開啟 Google Maps App（需已安裝）
    static func googleMapsAppURL(placeId: String, name: String = "") -> URL {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let encodedId = placeId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? placeId
        return URL(string: "comgooglemaps://?q=\(encodedName)&query_place_id=\(encodedId)")!
    }

    /// Universal Link：未安裝 Google Maps 時 Safari 開啟網頁版
    static func googleMapsWebURL(placeId: String, name: String = "") -> URL {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let encodedId = placeId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? placeId
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedName)&query_place_id=\(encodedId)")!
    }

    /// 主 App 使用（Universal Link，自動判斷是否安裝）
    static func googleMapsURL(placeId: String, name: String = "") -> URL {
        googleMapsWebURL(placeId: placeId, name: name)
    }
}
