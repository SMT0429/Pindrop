import Foundation

struct ParsedRestaurant {
    let name: String
    let location: String
}

enum GroqError: Error {
    case requestFailed
    case parseError
    case noRestaurantFound
}

actor GroqService {
    private static let endpoint = "https://api.groq.com/openai/v1/chat/completions"
    private static let model = "meta-llama/llama-4-scout-17b-16e-instruct"

    static func parseRestaurant(title: String, description: String) async throws -> [ParsedRestaurant] {
        let prompt = """
        以下是一則 Instagram 短片的 OG Metadata，請從中抽取所有提到的餐廳資訊。

        Title: \(title)
        Description: \(description)

        請以 JSON 格式回覆，只回覆 JSON，不要有其他文字：
        { "restaurants": [ { "name": "餐廳名稱", "location": "地點" } ] }

        若貼文提到多間餐廳，請全部列出（最多 10 間）。
        若只有一間，restaurants 陣列只放一個元素。
        若完全無法判斷為餐廳，請回覆：{ "restaurants": [] }

        location 填寫規則（優先順序由高至低）：
        1. 若有完整地址，填完整地址（如「台北市大安區忠孝東路四段216巷8弄1號」）
        2. 若有城市＋區，填「城市 區」（如「台北市信義區」）
        3. 若只有行政區或商圈，填該地名（如「信義區」、「西門町」、「東區」）
        4. 若有捷運站，填「XX站」（如「忠孝新生站」）
        5. 若只有縣市，填縣市名（如「台北」、「台中」）
        6. 若完全找不到任何地理線索，才填空字串 ""

        範例（多間餐廳）：
        { "restaurants": [
            { "name": "暇咖啡", "location": "九份" },
            { "name": "Simple Kaffa Sola", "location": "台北" }
        ] }
        """

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0,
            "response_format": ["type": "json_object"]
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.groqAPIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("[Pindrop] Groq HTTP status: \(statusCode)")

        guard (200...299).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "(no body)"
            print("[Pindrop] Groq error body: \(body.prefix(500))")
            throw GroqError.requestFailed
        }

        return try parseGroqResponse(data: data)
    }

    private static func parseGroqResponse(data: Data) throws -> [ParsedRestaurant] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String,
              let textData = text.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: textData) as? [String: Any],
              let list = root["restaurants"] as? [[String: Any]] else {
            throw GroqError.parseError
        }

        let results = list.compactMap { item -> ParsedRestaurant? in
            guard let name = item["name"] as? String, !name.isEmpty else { return nil }
            let location = item["location"] as? String ?? ""
            return ParsedRestaurant(name: name, location: location)
        }

        guard !results.isEmpty else {
            throw GroqError.noRestaurantFound
        }

        return results
    }
}
