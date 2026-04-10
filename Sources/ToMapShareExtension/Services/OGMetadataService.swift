import Foundation

struct OGMetadata {
    let title: String
    let description: String
}

enum OGMetadataError: Error {
    case fetchFailed
    case noMetadataFound
}

actor OGMetadataService {
    static func fetch(url: URL) async throws -> OGMetadata {
        var request = URLRequest(url: url)
        // 模擬瀏覽器 User-Agent，讓 Instagram 回傳含 OG metadata 的 HTML
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw OGMetadataError.fetchFailed
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw OGMetadataError.fetchFailed
        }

        let title = extractOGTag(named: "og:title", from: html)
        let description = extractOGTag(named: "og:description", from: html)

        guard title != nil || description != nil else {
            throw OGMetadataError.noMetadataFound
        }

        return OGMetadata(
            title: title ?? "",
            description: description ?? ""
        )
    }

    private static func extractOGTag(named property: String, from html: String) -> String? {
        // 匹配 <meta property="og:xxx" content="..."> 或 <meta content="..." property="og:xxx">
        let patterns = [
            #"<meta[^>]+property=[\"']"# + NSRegularExpression.escapedPattern(for: property) + #"[\"'][^>]+content=[\"']([^\"']+)[\"']"#,
            #"<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']"# + NSRegularExpression.escapedPattern(for: property) + #"[\"']"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
                    .decodingHTMLEntities()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
}

private extension String {
    /// 解碼所有 HTML entities，包含 &#x1234; 和 &amp; 等
    func decodingHTMLEntities() -> String {
        guard let data = self.data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
              ) else {
            // fallback：手動替換常見 entities
            return self
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
        }
        return attributed.string
    }
}
