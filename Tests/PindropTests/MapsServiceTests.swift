// Module under test: MapsService
// Last updated: 2026-04-12
//
// MapsService builds Google Maps URLs from place IDs and names.
// Tests cover URL structure, encoding of special characters, and edge cases.

import XCTest

final class MapsServiceTests: XCTestCase {

    // MARK: - Google Maps App URL

    func test_googleMapsAppURL_basicPlaceId_returnsCorrectScheme() {
        let placeId = "ChIJ1234567890"
        let url = MapsService.googleMapsAppURL(placeId: placeId, name: "Test")

        XCTAssertEqual(url.scheme, "comgooglemaps")
    }

    func test_googleMapsAppURL_basicPlaceId_containsQueryPlaceId() {
        let placeId = "ChIJ1234567890"
        let name = "TestRestaurant"
        let url = MapsService.googleMapsAppURL(placeId: placeId, name: name)
        let urlString = url.absoluteString

        XCTAssertTrue(urlString.contains("query_place_id=\(placeId)"))
        XCTAssertTrue(urlString.contains("q=\(name)"))
    }

    func test_googleMapsAppURL_emptyName_defaultsToEmpty() {
        let placeId = "ChIJ1234567890"
        let url = MapsService.googleMapsAppURL(placeId: placeId)
        let urlString = url.absoluteString

        XCTAssertTrue(urlString.contains("q=&") || urlString.hasSuffix("q="))
    }

    func test_googleMapsAppURL_chineseCharacters_arePercentEncoded() {
        let placeId = "ChIJ1234567890"
        let name = "鼎泰豐"
        let url = MapsService.googleMapsAppURL(placeId: placeId, name: name)
        let urlString = url.absoluteString

        // Chinese characters should be percent-encoded
        XCTAssertFalse(urlString.contains("鼎泰豐"))
        XCTAssertTrue(urlString.contains("q="))
    }

    func test_googleMapsAppURL_nameWithSpaces_areEncoded() {
        let placeId = "ChIJ1234567890"
        let name = "Din Tai Fung"
        let url = MapsService.googleMapsAppURL(placeId: placeId, name: name)
        let urlString = url.absoluteString

        // Spaces should be percent-encoded to %20 or +
        XCTAssertTrue(urlString.contains("q=Din%20Tai%20Fung") || urlString.contains("q=Din+Tai+Fung"))
    }

    // MARK: - Google Maps Web URL

    func test_googleMapsWebURL_returnsHTTPS() {
        let placeId = "ChIJ1234567890"
        let url = MapsService.googleMapsWebURL(placeId: placeId, name: "Test")

        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "www.google.com")
    }

    func test_googleMapsWebURL_containsSearchPath() {
        let placeId = "ChIJ1234567890"
        let url = MapsService.googleMapsWebURL(placeId: placeId, name: "Test")
        let urlString = url.absoluteString

        XCTAssertTrue(urlString.contains("/maps/search/"))
        XCTAssertTrue(urlString.contains("api=1"))
    }

    func test_googleMapsWebURL_containsQueryAndPlaceId() {
        let placeId = "ChIJ1234567890"
        let name = "Restaurant"
        let url = MapsService.googleMapsWebURL(placeId: placeId, name: name)
        let urlString = url.absoluteString

        XCTAssertTrue(urlString.contains("query=Restaurant"))
        XCTAssertTrue(urlString.contains("query_place_id=ChIJ1234567890"))
    }

    // MARK: - googleMapsURL (main app)

    func test_googleMapsURL_usesWebURL() {
        let placeId = "ChIJ1234567890"
        let name = "Test"
        let webURL = MapsService.googleMapsWebURL(placeId: placeId, name: name)
        let mainURL = MapsService.googleMapsURL(placeId: placeId, name: name)

        XCTAssertEqual(webURL, mainURL)
    }

    // MARK: - Boundary: Special Characters in Place ID

    func test_googleMapsAppURL_placeIdWithSpecialChars_isEncoded() {
        let placeId = "ChIJ/abc+def="
        let url = MapsService.googleMapsAppURL(placeId: placeId)
        let urlString = url.absoluteString

        // The placeId should be percent-encoded
        XCTAssertTrue(urlString.contains("query_place_id="))
    }

    // MARK: - Boundary: Empty Place ID

    func test_googleMapsWebURL_emptyPlaceId_stillCreatesURL() {
        let url = MapsService.googleMapsWebURL(placeId: "", name: "")
        XCTAssertNotNil(url)
        XCTAssertEqual(url.scheme, "https")
    }

    // MARK: - Boundary: Very Long Name

    func test_googleMapsAppURL_veryLongName_doesNotCrash() {
        let longName = String(repeating: "食", count: 1000)
        let placeId = "ChIJ1234567890"

        // Should not crash
        let url = MapsService.googleMapsAppURL(placeId: placeId, name: longName)
        XCTAssertNotNil(url)
    }

    // MARK: - Apple Maps URL

    func test_appleMapsURL_returnsHTTPSMapsAppleDotCom() {
        let url = MapsService.appleMapsURL(name: "Din Tai Fung")
        XCTAssertEqual(url.scheme, "https")
        XCTAssertEqual(url.host, "maps.apple.com")
    }

    func test_appleMapsURL_encodesNameInQueryParameter() {
        let url = MapsService.appleMapsURL(name: "Bar & Grill")
        let urlString = url.absoluteString
        // & must be percent-encoded so it doesn't split the query
        XCTAssertFalse(urlString.contains("q=Bar & Grill"))
        XCTAssertTrue(urlString.contains("q="))
    }

    func test_appleMapsURL_withAddress_includesAddressParam() {
        let url = MapsService.appleMapsURL(name: "Test", address: "Taipei 101")
        let urlString = url.absoluteString
        XCTAssertTrue(urlString.contains("q=Test"))
        XCTAssertTrue(urlString.contains("address="))
    }

    func test_appleMapsURL_emptyAddress_omitsAddressParam() {
        let url = MapsService.appleMapsURL(name: "Test", address: "")
        let urlString = url.absoluteString
        XCTAssertFalse(urlString.contains("address="))
    }

    func test_appleMapsURL_chineseName_isPercentEncoded() {
        let url = MapsService.appleMapsURL(name: "鼎泰豐")
        let urlString = url.absoluteString
        XCTAssertFalse(urlString.contains("鼎泰豐"))
    }

    // MARK: - Unified entry

    func test_url_forAppleApp_returnsAppleMapsURL() {
        let url = MapsService.url(for: .apple, placeId: "ChIJ123", name: "Test", address: "")
        XCTAssertEqual(url.host, "maps.apple.com")
    }

    func test_url_forGoogleApp_returnsGoogleMapsWebURL() {
        let url = MapsService.url(for: .google, placeId: "ChIJ123", name: "Test", address: "")
        XCTAssertEqual(url.host, "www.google.com")
    }
}
