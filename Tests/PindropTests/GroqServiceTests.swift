// Module under test: GroqService (response parsing logic)
// Last updated: 2026-04-12
//
// GroqService is an actor that calls the Groq API for restaurant extraction.
// Since the parsing method is private, we test via protocol-based mock of URLSession.
// For the response parsing logic, we use a helper that exposes the parsing for testing.
//
// NOTE: The current GroqService uses URLSession.shared directly, making it
// difficult to unit test without refactoring. The tests below document what
// SHOULD be tested and provide a parseGroqResponse test helper.
// A recommended refactor is to inject URLSession via a protocol.

import XCTest

// MARK: - Test Helper: Expose Groq Response Parsing

/// Since GroqService.parseGroqResponse is private, we replicate the parsing
/// logic here for testing purposes. In a real project, this would be refactored
/// to use dependency injection.
private enum GroqResponseParser {

    static func parse(data: Data) throws -> [ParsedRestaurant] {
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

final class GroqServiceTests: XCTestCase {

    // MARK: - Response Parsing: Happy Path

    func test_parseResponse_singleRestaurant_returnsOne() throws {
        let responseJSON = makeGroqResponse(restaurants: [
            ["name": "暇咖啡", "location": "九份"]
        ])
        let data = try JSONSerialization.data(withJSONObject: responseJSON)

        let results = try GroqResponseParser.parse(data: data)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "暇咖啡")
        XCTAssertEqual(results[0].location, "九份")
    }

    func test_parseResponse_multipleRestaurants_returnsAll() throws {
        let responseJSON = makeGroqResponse(restaurants: [
            ["name": "暇咖啡", "location": "九份"],
            ["name": "Simple Kaffa Sola", "location": "台北"]
        ])
        let data = try JSONSerialization.data(withJSONObject: responseJSON)

        let results = try GroqResponseParser.parse(data: data)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].name, "暇咖啡")
        XCTAssertEqual(results[1].name, "Simple Kaffa Sola")
    }

    func test_parseResponse_emptyLocation_returnsEmptyString() throws {
        let responseJSON = makeGroqResponse(restaurants: [
            ["name": "好餐廳", "location": ""]
        ])
        let data = try JSONSerialization.data(withJSONObject: responseJSON)

        let results = try GroqResponseParser.parse(data: data)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].location, "")
    }

    func test_parseResponse_missingLocation_defaultsToEmpty() throws {
        let responseJSON = makeGroqResponse(restaurants: [
            ["name": "好餐廳"]
        ])
        let data = try JSONSerialization.data(withJSONObject: responseJSON)

        let results = try GroqResponseParser.parse(data: data)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].location, "")
    }

    // MARK: - Response Parsing: Error Paths

    func test_parseResponse_emptyRestaurantsArray_throwsNoRestaurantFound() {
        let responseJSON = makeGroqResponse(restaurants: [])

        XCTAssertThrowsError(try {
            let data = try JSONSerialization.data(withJSONObject: responseJSON)
            _ = try GroqResponseParser.parse(data: data)
        }()) { error in
            XCTAssertTrue(error is GroqError)
            if let groqError = error as? GroqError {
                XCTAssertEqual(groqError, .noRestaurantFound)
            }
        }
    }

    func test_parseResponse_restaurantWithEmptyName_isFiltered() {
        let responseJSON = makeGroqResponse(restaurants: [
            ["name": "", "location": "台北"],
            ["name": "有效餐廳", "location": "台中"]
        ])

        XCTAssertNoThrow(try {
            let data = try JSONSerialization.data(withJSONObject: responseJSON)
            let results = try GroqResponseParser.parse(data: data)
            XCTAssertEqual(results.count, 1)
            XCTAssertEqual(results[0].name, "有效餐廳")
        }())
    }

    func test_parseResponse_allRestaurantsEmptyName_throwsNoRestaurantFound() {
        let responseJSON = makeGroqResponse(restaurants: [
            ["name": "", "location": "台北"],
            ["name": "", "location": "台中"]
        ])

        XCTAssertThrowsError(try {
            let data = try JSONSerialization.data(withJSONObject: responseJSON)
            _ = try GroqResponseParser.parse(data: data)
        }()) { error in
            XCTAssertTrue(error is GroqError)
        }
    }

    func test_parseResponse_malformedJSON_throwsParseError() {
        let malformedData = "not json".data(using: .utf8)!

        XCTAssertThrowsError(try GroqResponseParser.parse(data: malformedData)) { error in
            XCTAssertTrue(error is GroqError)
            if let groqError = error as? GroqError {
                XCTAssertEqual(groqError, .parseError)
            }
        }
    }

    func test_parseResponse_missingChoices_throwsParseError() throws {
        let json: [String: Any] = ["id": "chatcmpl-123"]
        let data = try JSONSerialization.data(withJSONObject: json)

        XCTAssertThrowsError(try GroqResponseParser.parse(data: data)) { error in
            XCTAssertTrue(error is GroqError)
        }
    }

    func test_parseResponse_emptyChoicesArray_throwsParseError() throws {
        let json: [String: Any] = ["choices": []]
        let data = try JSONSerialization.data(withJSONObject: json)

        XCTAssertThrowsError(try GroqResponseParser.parse(data: data)) { error in
            XCTAssertTrue(error is GroqError)
        }
    }

    func test_parseResponse_contentNotJSON_throwsParseError() throws {
        let json: [String: Any] = [
            "choices": [[
                "message": [
                    "content": "This is not JSON at all, just free text."
                ]
            ]]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        XCTAssertThrowsError(try GroqResponseParser.parse(data: data)) { error in
            XCTAssertTrue(error is GroqError)
        }
    }

    func test_parseResponse_contentMissingRestaurantsKey_throwsParseError() throws {
        let contentJSON = "{\"result\": []}"
        let json: [String: Any] = [
            "choices": [[
                "message": [
                    "content": contentJSON
                ]
            ]]
        ]
        let data = try JSONSerialization.data(withJSONObject: json)

        XCTAssertThrowsError(try GroqResponseParser.parse(data: data)) { error in
            XCTAssertTrue(error is GroqError)
        }
    }

    // MARK: - Boundary: Large Response

    func test_parseResponse_tenRestaurants_returnsAll() throws {
        var restaurants: [[String: String]] = []
        for i in 1...10 {
            restaurants.append(["name": "餐廳\(i)", "location": "地點\(i)"])
        }
        let responseJSON = makeGroqResponse(restaurants: restaurants)
        let data = try JSONSerialization.data(withJSONObject: responseJSON)

        let results = try GroqResponseParser.parse(data: data)

        XCTAssertEqual(results.count, 10)
    }

    // MARK: - Boundary: Unicode in Restaurant Names

    func test_parseResponse_emojiInName_isParsed() throws {
        let responseJSON = makeGroqResponse(restaurants: [
            ["name": "🔥火鍋王", "location": "台北"]
        ])
        let data = try JSONSerialization.data(withJSONObject: responseJSON)

        let results = try GroqResponseParser.parse(data: data)

        XCTAssertEqual(results[0].name, "🔥火鍋王")
    }

    // MARK: - Helpers

    private func makeGroqResponse(restaurants: [[String: Any]]) -> [String: Any] {
        let contentObject: [String: Any] = ["restaurants": restaurants]
        let contentString: String
        if let contentData = try? JSONSerialization.data(withJSONObject: contentObject),
           let str = String(data: contentData, encoding: .utf8) {
            contentString = str
        } else {
            contentString = "{\"restaurants\": []}"
        }

        return [
            "choices": [[
                "message": [
                    "role": "assistant",
                    "content": contentString
                ]
            ]]
        ]
    }
}

// MARK: - GroqError Equatable (for assertion)
extension GroqError: @retroactive Equatable {
    public static func == (lhs: GroqError, rhs: GroqError) -> Bool {
        switch (lhs, rhs) {
        case (.requestFailed, .requestFailed): return true
        case (.parseError, .parseError): return true
        case (.noRestaurantFound, .noRestaurantFound): return true
        default: return false
        }
    }
}
