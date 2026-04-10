import Foundation

enum MapsService {
    /// 使用 Google Maps URLs API 格式：query_place_id 參數才是正確的 place_id 導航方式。
    /// Google Maps App 透過 Universal Links 自動接管；未安裝時 Safari 開啟網頁版。
    static func googleMapsURL(placeId: String, name: String = "") -> URL {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let encodedId = placeId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? placeId
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedName)&query_place_id=\(encodedId)")!
    }

    static func googleMapsAppURL(placeId: String, name: String = "") -> URL { googleMapsURL(placeId: placeId, name: name) }
    static func googleMapsWebURL(placeId: String, name: String = "") -> URL { googleMapsURL(placeId: placeId, name: name) }
}
