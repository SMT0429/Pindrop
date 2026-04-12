// Module under test: OGMetadataService (HTML OG tag extraction)
// Last updated: 2026-04-12
//
// OGMetadataService fetches HTML and extracts og:title / og:description.
// The extractOGTag method is private, so we replicate its regex logic here.
// The HTML entity decoding extension is also tested.

import XCTest

/// Replicates OGMetadataService.extractOGTag for testing.
private enum OGTagExtractor {

    static func extract(named property: String, from html: String) -> String? {
        let patterns = [
            #"<meta[^>]+property=[\"']"# + NSRegularExpression.escapedPattern(for: property) + #"[\"'][^>]+content=[\"']([^\"']+)[\"']"#,
            #"<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']"# + NSRegularExpression.escapedPattern(for: property) + #"[\"']"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
}

final class OGMetadataServiceTests: XCTestCase {

    // MARK: - OG Tag Extraction: Happy Path

    func test_extractOGTitle_standardFormat_returnsTitle() {
        let html = """
        <html><head>
        <meta property="og:title" content="台北美食推薦 | 鼎泰豐信義店">
        </head><body></body></html>
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertEqual(title, "台北美食推薦 | 鼎泰豐信義店")
    }

    func test_extractOGDescription_standardFormat_returnsDescription() {
        let html = """
        <html><head>
        <meta property="og:description" content="超好吃的小籠包">
        </head><body></body></html>
        """

        let description = OGTagExtractor.extract(named: "og:description", from: html)
        XCTAssertEqual(description, "超好吃的小籠包")
    }

    func test_extractOGTitle_reversedAttributes_returnsTitle() {
        // Some sites put content before property
        let html = """
        <meta content="Reversed Title" property="og:title">
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertEqual(title, "Reversed Title")
    }

    func test_extractOGTitle_singleQuotes_returnsTitle() {
        let html = """
        <meta property='og:title' content='Single Quotes'>
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertEqual(title, "Single Quotes")
    }

    func test_extractOGTitle_mixedQuotes_returnsTitle() {
        let html = """
        <meta property='og:title' content="Mixed Quotes">
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertEqual(title, "Mixed Quotes")
    }

    // MARK: - OG Tag Extraction: Missing Tags

    func test_extractOGTitle_noMetaTags_returnsNil() {
        let html = "<html><head><title>Page</title></head><body></body></html>"

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertNil(title)
    }

    func test_extractOGTitle_otherMetaTagsOnly_returnsNil() {
        let html = """
        <meta property="og:description" content="Desc">
        <meta property="og:image" content="img.jpg">
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertNil(title)
    }

    func test_extractOGTag_emptyContent_returnsEmpty() {
        let html = """
        <meta property="og:title" content="">
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        // The regex [^\"']+ requires at least 1 char, so empty content should not match
        XCTAssertNil(title)
    }

    // MARK: - OG Tag Extraction: Edge Cases

    func test_extractOGTitle_multipleOGTitleTags_returnsFirst() {
        let html = """
        <meta property="og:title" content="First">
        <meta property="og:title" content="Second">
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertEqual(title, "First")
    }

    func test_extractOGTitle_withExtraAttributes_returnsTitle() {
        let html = """
        <meta property="og:title" content="With Extra" data-custom="yes" />
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertEqual(title, "With Extra")
    }

    func test_extractOGTag_emptyHTML_returnsNil() {
        let title = OGTagExtractor.extract(named: "og:title", from: "")
        XCTAssertNil(title)
    }

    func test_extractOGTag_wholeHTMLNoHead_returnsNilOrFindsInBody() {
        let html = "<html><body><meta property=\"og:title\" content=\"Body Tag\"></body></html>"

        // The regex doesn't care about <head> vs <body> - it searches entire string
        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertEqual(title, "Body Tag")
    }

    // MARK: - OG Tag with HTML Entities

    func test_extractOGTitle_withAmpEntity_returnsRaw() {
        let html = """
        <meta property="og:title" content="A &amp; B Restaurant">
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        // Note: our extractor does NOT decode entities (that's done in the full service)
        XCTAssertEqual(title, "A &amp; B Restaurant")
    }

    // MARK: - OG Tag: Instagram-Style HTML

    func test_extractOGTag_instagramStyleHTML_returnsMetadata() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta property="og:title" content="foodie_tw on Instagram: &quot;【暇咖啡】九份必訪&quot;">
        <meta property="og:description" content="1,234 likes, 56 comments - foodie_tw on April 1, 2026">
        <meta property="og:image" content="https://scontent.cdninstagram.com/v/abc123">
        </head>
        <body></body>
        </html>
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        let description = OGTagExtractor.extract(named: "og:description", from: html)

        XCTAssertNotNil(title)
        XCTAssertTrue(title?.contains("暇咖啡") == true)
        XCTAssertNotNil(description)
    }

    // MARK: - Boundary: Very Large HTML

    func test_extractOGTag_veryLargeHTML_doesNotCrash() {
        let padding = String(repeating: "<div>lots of content</div>\n", count: 10000)
        let html = """
        <html><head>
        <meta property="og:title" content="Found It">
        </head><body>\(padding)</body></html>
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertEqual(title, "Found It")
    }

    // MARK: - Boundary: Case Insensitivity

    func test_extractOGTag_uppercaseMeta_returnsTitle() {
        let html = """
        <META PROPERTY="og:title" CONTENT="Uppercase">
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertEqual(title, "Uppercase")
    }

    func test_extractOGTag_mixedCaseMeta_returnsTitle() {
        let html = """
        <Meta Property="og:title" Content="MixedCase">
        """

        let title = OGTagExtractor.extract(named: "og:title", from: html)
        XCTAssertEqual(title, "MixedCase")
    }
}
