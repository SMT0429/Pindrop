import Foundation

enum PlacesError: Error {
    case requestFailed
    case parseError
}

actor PlacesService {
    private static let endpoint = "https://places.googleapis.com/v1/places:searchText"

    static func search(name: String, location: String) async throws -> [Place] {
        let query = location.isEmpty ? name : "\(name) \(location)"

        let body: [String: Any] = [
            "textQuery": query,
            "maxResultCount": 5,
            "languageCode": "zh-TW"
        ]

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Config.googlePlacesAPIKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.id,places.displayName,places.formattedAddress", forHTTPHeaderField: "X-Goog-FieldMask")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw PlacesError.requestFailed
        }

        return try parsePlacesResponse(data: data)
    }

    private static func parsePlacesResponse(data: Data) throws -> [Place] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PlacesError.parseError
        }

        // 回傳 0 筆時 "places" key 可能不存在
        guard let placesArray = json["places"] as? [[String: Any]] else {
            return []
        }

        return placesArray.compactMap { dict -> Place? in
            guard let id = dict["id"] as? String,
                  let displayName = dict["displayName"] as? [String: String],
                  let name = displayName["text"] else { return nil }

            let address = dict["formattedAddress"] as? String ?? ""
            return Place(id: id, name: name, address: address)
        }
    }
}
