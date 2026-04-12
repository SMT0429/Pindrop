import Foundation

/// 從 OG metadata 文字中直接抽取餐廳名稱與地址，不需要呼叫 Gemini API。
/// 適用於台灣美食 IG 貼文常見格式（【店名】、📍/🚩地址 等）。
enum LocalParser {

    static func parse(text: String) -> ParsedRestaurant? {
        let name = extractName(from: text)
        let location = extractLocation(from: text)

        guard let name, !name.isEmpty else { return nil }
        return ParsedRestaurant(name: name, location: location ?? "")
    }

    // MARK: - Name Extraction

    private static func extractName(from text: String) -> String? {
        // 優先順序：
        // 1. 【店名】
        // 2. 「店名」（緊接在表情符號後）
        // 3. 英文店名（全大寫 hashtag，例如 #TACOJOE）
        let patterns: [(String, Int)] = [
            (#"【([^】]{1,30})】"#, 1),                   // 【TacoJoe】
            (#"[📍🚩🏠🍽️]\s*([^\n,，。.]{2,30})\s*\n"#, 1), // 📍 店名（換行前）
        ]

        for (pattern, group) in patterns {
            if let result = capture(pattern: pattern, in: text, group: group) {
                let cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty && !looksLikeAddress(cleaned) { return cleaned }
            }
        }

        return nil
    }

    /// 判斷一段文字是否像「地址」而非「店名」。
    /// 用於 emoji-prefixed pattern 既會配到 📍店名 也會配到 📍地址 的情境。
    private static func looksLikeAddress(_ text: String) -> Bool {
        // 1. 含明確地址關鍵字
        let addressKeywords = ["號", "樓", "路", "街", "段", "巷", "弄", "區",
                               "市", "縣", "鄉", "鎮", "里", "村"]
        for keyword in addressKeywords where text.contains(keyword) {
            return true
        }
        // 2. 以數字開頭（例如 "100 台北市..."）
        if let first = text.first, first.isNumber { return true }
        return false
    }

    // MARK: - Location Extraction

    private static func extractLocation(from text: String) -> String? {
        let patterns: [(String, Int)] = [
            // 完整地址（含市/縣）
            (#"([台臺][北南中東西](?:市|縣)[^\n,，。]{2,40}(?:號|樓|F))"#, 1),
            (#"((?:新北|桃園|台中|臺中|台南|臺南|高雄|新竹|基隆)[^\n,，。]{2,40}(?:號|樓|F))"#, 1),
            // 🚩 後面的地址
            (#"🚩\s*([^\n]{4,50})"#, 1),
            (#"📍\s*([^\n]{4,50})"#, 1),
            // 地區名（捷運站或知名區域）
            (#"(忠孝新生|信義區|大安區|中山區|松山區|內湖區|士林區|北投區|文山區|南港區|萬華區|中正區)"#, 1),
        ]

        for (pattern, group) in patterns {
            if let result = capture(pattern: pattern, in: text, group: group) {
                let cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty { return cleaned }
            }
        }

        return nil
    }

    // MARK: - Helpers

    private static func capture(pattern: String, in text: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: group), in: text) else { return nil }
        return String(text[range])
    }
}
