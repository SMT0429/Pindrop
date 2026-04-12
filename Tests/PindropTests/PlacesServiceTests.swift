// Module under test: PlacesService (response parsing logic)
// Last updated: 2026-04-12
//
// PlacesService searches Google Places API and parses response JSON.
// Like GroqService, the parsing is private, so we replicate it here for testing.
// The actual network call should be tested with protocol-based DI in a refactor.

import XCTest

/// Replicates PlacesService.parsePlacesResponse for testing.
private enum PlacesResponseParser {

    static func parse(data: Data) throws -> [Place] {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PlacesError.parseError
        }

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

final class PlacesServiceTests: XCTestCase {

    // MARK: - Response Parsing: Happy Path

    func test_parseResponse_singlePlace_returnsOne() throws {
        let json = makePlacesResponse(places: [
            makePlaceDict(id: "ChIJ123", name: "鼎泰豐", address: "台北市信義區松高路12號")
        ])
        let data = try JSONSerialization.data(withJSONObject: json)

        let results = try PlacesResponseParser.parse(data: data)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].id, "ChIJ123")
        XCTAssertEqual(results[0].name, "鼎泰豐")
        XCTAssertEqual(results[0].address, "台北市信義區松高路12號")
    }

    func test_parseResponse_multiplePlaces_returnsAll() throws {
        let json = makePlacesResponse(places: [
            makePlaceDict(id: "ChIJ123", name: "鼎泰豐", address: "台北"),
            makePlaceDict(id: "ChIJ456", name: "添好運", address: "台北"),
            makePlaceDict(id: "ChIJ789", name: "春水堂", address: "台中")
        ])
        let data = try JSONSerialization.data(withJSONObject: json)

        let results = try PlacesResponseParser.parse(data: data)

        XCTAssertEqual(results.count, 3)
    }

    func test_parseResponse_missingAddress_defaultsToEmpty() throws {
        let placeDict: [String: Any] = [
            "id": "ChIJ123",
            "displayName": ["text": "好餐廳", "languageCode": "zh-TW"]
            // No formattedAddress
        ]
        let json: [String: Any] = ["places": [placeDict]]
        let data = try JSONSerialization.data(withJSONObject: json)

        let results = try PlacesResponseParser.parse(data: data)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].address, "")
    }

    // MARK: - Response Parsing: Empty / No Results

    func test_parseResponse_emptyPlacesArray_returnsEmpty() throws {
        let json: [String: Any] = ["places": []]
        let data = try JSONSerialization.data(withJSONObject: json)

        let results = try PlacesResponseParser.parse(data: data)

        XCTAssertTrue(results.isEmpty)
    }

    func test_parseResponse_missingPlacesKey_returnsEmpty() throws {
        let json: [String: Any] = ["status": "OK"]
        let data = try JSONSerialization.data(withJSONObject: json)

        let results = try PlacesResponseParser.parse(data: data)

        XCTAssertTrue(results.isEmpty)
    }

    func test_parseResponse_emptyJSON_returnsEmpty() throws {
        let json: [String: Any] = [:]
        let data = try JSONSerialization.data(withJSONObject: json)

        let results = try PlacesResponseParser.parse(data: data)

        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - Response Parsing: Malformed Data

    func test_parseResponse_notJSON_throwsParseError() {
        let data = "not json at all".data(using: .utf8)!

        XCTAssertThrowsError(try PlacesResponseParser.parse(data: data)) { error in
            XCTAssertTrue(error is PlacesError)
        }
    }

    func test_parseResponse_placeWithoutId_isSkipped() throws {
        let placeDict: [String: Any] = [
            // No "id"
            "displayName": ["text": "好餐廳"],
            "formattedAddress": "台北"
        ]
        let json: [String: Any] = ["places": [placeDict]]
        let data = try JSONSerialization.data(withJSONObject: json)

        let results = try PlacesResponseParser.parse(data: data)

        XCTAssertTrue(results.isEmpty)
    }

    func test_parseResponse_placeWithoutDisplayName_isSkipped() throws {
        let placeDict: [String: Any] = [
            "id": "ChIJ123",
            "formattedAddress": "台北"
        ]
        let json: [String: Any] = ["places": [placeDict]]
        let data = try JSONSerialization.data(withJSONObject: json)

        let results = try PlacesResponseParser.parse(data: data)

        XCTAssertTrue(results.isEmpty)
    }

    func test_parseResponse_placeWithoutTextInDisplayName_isSkipped() throws {
        let placeDict: [String: Any] = [
            "id": "ChIJ123",
            "displayName": ["languageCode": "zh-TW"]  // missing "text"
        ]
        let json: [String: Any] = ["places": [placeDict]]
        let data = try JSONSerialization.data(withJSONObject: json)

        let results = try PlacesResponseParser.parse(data: data)

        XCTAssertTrue(results.isEmpty)
    }

    func test_parseResponse_mixOfValidAndInvalid_returnsOnlyValid() throws {
        let validPlace = makePlaceDict(id: "ChIJ123", name: "好餐廳", address: "台北")
        let invalidPlace: [String: Any] = ["id": "ChIJ456"]  // missing displayName
        let json: [String: Any] = ["places": [validPlace, invalidPlace]]
        let data = try JSONSerialization.data(withJSONObject: json)

        let results = try PlacesResponseParser.parse(data: data)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].name, "好餐廳")
    }

    // MARK: - Boundary: Query Construction

    func test_searchQuery_emptyLocation_usesNameOnly() {
        let name = "鼎泰豐"
        let location = ""
        let query = location.isEmpty ? name : "\(name) \(location)"

        XCTAssertEqual(query, "鼎泰豐")
    }

    func test_searchQuery_withLocation_combinesNameAndLocation() {
        let name = "鼎泰豐"
        let location = "台北信義區"
        let query = location.isEmpty ? name : "\(name) \(location)"

        XCTAssertEqual(query, "鼎泰豐 台北信義區")
    }

    // MARK: - Helpers

    private func makePlaceDict(id: String, name: String, address: String) -> [String: Any] {
        return [
            "id": id,
            "displayName": ["text": name, "languageCode": "zh-TW"],
            "formattedAddress": address
        ]
    }

    private func makePlacesResponse(places: [[String: Any]]) -> [String: Any] {
        return ["places": places]
    }
}
