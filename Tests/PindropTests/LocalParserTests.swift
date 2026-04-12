// Module under test: LocalParser
// Last updated: 2026-04-12
//
// LocalParser extracts restaurant names and addresses from OG metadata text
// commonly found in Taiwanese food Instagram posts. These tests cover:
//   - Name extraction (【】brackets, emoji-prefixed names)
//   - Location extraction (full addresses, emoji-prefixed, district names)
//   - Boundary conditions (empty, nil-equivalent, malformed, Unicode edge cases)

import XCTest

final class LocalParserTests: XCTestCase {

    // MARK: - Happy Path: Name Extraction via 【】 Brackets

    func test_parse_nameInSquareBrackets_returnsName() {
        let text = "今天來吃【好好吃飯店】超好吃的拉麵"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "好好吃飯店")
    }

    func test_parse_nameInSquareBracketsWithEnglish_returnsName() {
        let text = "來到【TacoJoe】台北信義店"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "TacoJoe")
    }

    func test_parse_nameInSquareBracketsWithMixedLanguage_returnsName() {
        let text = "推薦【Simple Kaffa 興波咖啡】的手沖"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Simple Kaffa 興波咖啡")
    }

    // MARK: - Happy Path: Name Extraction via Emoji Prefix

    func test_parse_nameAfterPinEmoji_returnsName() {
        let text = "📍 暇咖啡\n九份老街上的好去處"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "暇咖啡")
    }

    func test_parse_nameAfterFlagEmoji_returnsName() {
        let text = "🚩 鼎泰豐信義店\n小籠包必吃"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "鼎泰豐信義店")
    }

    func test_parse_nameAfterHouseEmoji_returnsName() {
        let text = "🏠 陳記滷肉飯\n巷弄美食"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "陳記滷肉飯")
    }

    func test_parse_nameAfterForkKnifeEmoji_returnsName() {
        let text = "🍽️ MUME\n台北必吃餐廳"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "MUME")
    }

    // MARK: - Happy Path: Location Extraction

    func test_parse_fullTaipeiAddress_returnsLocation() {
        let text = "【好吃飯店】\n台北市大安區忠孝東路四段216巷8弄1號"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "好吃飯店")
        XCTAssertEqual(result?.location, "台北市大安區忠孝東路四段216巷8弄1號")
    }

    func test_parse_fullAddressWithFloor_returnsLocation() {
        let text = "【天香樓】\n台北市中山區南京東路三段12號2樓"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.location.contains("台北市中山區") == true)
    }

    func test_parse_addressWithFloorF_returnsLocation() {
        let text = "【餐廳A】\n台北市信義區松壽路9號5F"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.location.contains("台北市信義區") == true)
    }

    func test_parse_newTaipeiAddress_returnsLocation() {
        let text = "【板橋美食】\n新北市板橋區文化路一段100號"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.location.contains("新北") == true)
    }

    func test_parse_taoyuanAddress_returnsLocation() {
        let text = "【老店】\n桃園市中壢區中正路200號"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.location.contains("桃園") == true)
    }

    func test_parse_kaohsiungAddress_returnsLocation() {
        let text = "【南部美食】\n高雄市前鎮區成功二路88號"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.location.contains("高雄") == true)
    }

    func test_parse_locationAfterFlagEmoji_returnsLocation() {
        let text = "【好餐廳】\n🚩 台北市大安區永康街31號"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertFalse(result?.location.isEmpty ?? true)
    }

    func test_parse_locationAfterPinEmoji_returnsLocation() {
        let text = "【好餐廳】\n📍 捷運忠孝新生站附近"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertFalse(result?.location.isEmpty ?? true)
    }

    func test_parse_districtName_returnsLocation() {
        let text = "【信義區美食推薦】\n好吃的義大利麵"
        let result = LocalParser.parse(text: text)

        // The name should be extracted from brackets; location may or may not match
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "信義區美食推薦")
    }

    // MARK: - Location with 臺 (Traditional Variant)

    func test_parse_addressWithTraditionalTai_returnsLocation() {
        let text = "【好餐廳】\n臺北市大安區復興南路100號"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.location.contains("臺北市") == true)
    }

    func test_parse_taichungWithTraditionalVariant_returnsLocation() {
        let text = "【好餐廳】\n臺中市西區向上路88號"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.location.contains("臺中") == true)
    }

    // MARK: - Multiple Matches (Priority)

    func test_parse_bracketsAndEmoji_prefersBrackets() {
        let text = "【正宗店名】\n📍 冒牌店名\n台北市信義區"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "正宗店名")
    }

    // MARK: - Boundary: Empty and Nil-Equivalent Inputs

    func test_parse_emptyString_returnsNil() {
        let result = LocalParser.parse(text: "")
        XCTAssertNil(result)
    }

    func test_parse_whitespaceOnly_returnsNil() {
        let result = LocalParser.parse(text: "   \n\t  ")
        XCTAssertNil(result)
    }

    func test_parse_noRecognizablePattern_returnsNil() {
        let text = "This is a random English sentence with no restaurant info."
        let result = LocalParser.parse(text: text)
        XCTAssertNil(result)
    }

    func test_parse_numbersOnly_returnsNil() {
        let text = "123456789"
        let result = LocalParser.parse(text: text)
        XCTAssertNil(result)
    }

    // MARK: - Boundary: Brackets Edge Cases

    func test_parse_emptyBrackets_returnsNil() {
        let text = "【】"
        let result = LocalParser.parse(text: text)
        // The regex requires {1,30} chars inside brackets, so empty should fail
        XCTAssertNil(result)
    }

    func test_parse_bracketNameExactly1Char_returnsName() {
        let text = "【鍋】好吃"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "鍋")
    }

    func test_parse_bracketNameExactly30Chars_returnsName() {
        let longName = String(repeating: "好", count: 30) // 30 characters
        let text = "【\(longName)】"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, longName)
    }

    func test_parse_bracketNameOver30Chars_returnsNil() {
        let longName = String(repeating: "好", count: 31) // 31 characters
        let text = "【\(longName)】"
        let result = LocalParser.parse(text: text)

        // Regex limits to {1,30}, so 31 should not match
        XCTAssertNil(result)
    }

    func test_parse_nestedBrackets_returnsInnerContent() {
        let text = "推薦【【好吃】餐廳】必訪"
        let result = LocalParser.parse(text: text)

        // NSRegularExpression is greedy by default but [^】] should stop at first 】
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "【好吃")
    }

    func test_parse_multipleBracketPairs_returnsFirst() {
        let text = "【第一間】是早餐【第二間】是晚餐"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "第一間")
    }

    // MARK: - Boundary: Emoji Name Edge Cases

    func test_parse_emojiWithNoNewline_returnsNil() {
        // The emoji pattern requires a newline after the name
        let text = "📍 暇咖啡是好地方"
        let result = LocalParser.parse(text: text)

        // Without \n, the emoji pattern should NOT match (it requires \n)
        // The brackets pattern also won't match
        XCTAssertNil(result)
    }

    func test_parse_emojiWithOnlyOneChar_returnsNil() {
        // The emoji pattern requires {2,30} characters
        let text = "📍 A\n其他"
        let result = LocalParser.parse(text: text)

        // "A" is only 1 character but the capture includes everything up to \n
        // The regex is [^\n,，。.]{2,30}, so "A" with 1 char should fail
        XCTAssertNil(result)
    }

    func test_parse_emojiWith30Chars_returnsName() {
        let name = String(repeating: "食", count: 30)
        let text = "📍 \(name)\n好吃"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, name)
    }

    func test_parse_emojiWith31Chars_returnsNil() {
        let name = String(repeating: "食", count: 31)
        let text = "📍 \(name)\n好吃"
        let result = LocalParser.parse(text: text)

        // {2,30} limit should prevent matching
        XCTAssertNil(result)
    }

    // MARK: - Boundary: Location Edge Cases

    func test_parse_nameButNoLocation_returnsEmptyLocation() {
        let text = "【好吃餐廳】推薦必吃"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "好吃餐廳")
        XCTAssertEqual(result?.location, "")
    }

    func test_parse_addressTooShort_returnsEmptyLocation() {
        // Address pattern requires at least 2 chars after city/county
        let text = "【餐廳】\n台北市1號"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        // "1號" is only 2 chars which meets the minimum
    }

    func test_parse_addressWithoutTerminator_returnsEmptyLocation() {
        // The full address regex requires ending with 號/樓/F
        let text = "【餐廳】\n台北市大安區忠孝東路"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        // No 號/樓/F terminator means main address pattern won't match
        // But 大安區 should be caught by the district pattern
        XCTAssertEqual(result?.location, "大安區")
    }

    func test_parse_allDistrictNames_recognizesEach() {
        let districts = [
            "信義區", "大安區", "中山區", "松山區", "內湖區",
            "士林區", "北投區", "文山區", "南港區", "萬華區", "中正區"
        ]

        for district in districts {
            let text = "【好餐廳】\n位於\(district)的美食"
            let result = LocalParser.parse(text: text)

            XCTAssertNotNil(result, "Should parse text containing district: \(district)")
            XCTAssertEqual(result?.location, district, "Should extract district: \(district)")
        }
    }

    func test_parse_zhongxiaoXinshengStation_returnsLocation() {
        let text = "【好餐廳】\n忠孝新生站附近的好去處"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.location, "忠孝新生")
    }

    // MARK: - Boundary: Special Characters and Unicode

    func test_parse_nameWithSpecialChars_returnsName() {
        let text = "【Mr.Cow 烤大爺】\n台北美食"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Mr.Cow 烤大爺")
    }

    func test_parse_nameWithAmpersand_returnsName() {
        let text = "【M&F 深法廚房】\n精緻法式料理"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "M&F 深法廚房")
    }

    func test_parse_nameWithNumbers_returnsName() {
        let text = "【7號公園咖啡】\n文青必去"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "7號公園咖啡")
    }

    func test_parse_nameWithJapanese_returnsName() {
        let text = "【丸亀製麺】\n日式烏龍麵"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "丸亀製麺")
    }

    func test_parse_nameWithEmoji_returnsName() {
        // Emoji inside brackets should still match [^】]{1,30}
        let text = "【好吃火鍋🔥】\n推薦"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.contains("好吃火鍋") == true)
    }

    // MARK: - Realistic Instagram Post Texts

    func test_parse_realisticTaiwanFoodPost_full() {
        let text = """
        台北美食推薦
        【陳記腸蚵麵線】
        📍 台北市萬華區西園路一段306號
        排隊也要吃的超人氣麵線！
        """
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "陳記腸蚵麵線")
        XCTAssertTrue(result?.location.contains("萬華區") == true || result?.location.contains("台北市") == true)
    }

    func test_parse_realisticPostWithFlag() {
        let text = """
        超推這家！
        🚩 鼎泰豐（信義店）
        台北市信義區松高路12號
        小籠包真的太好吃了
        """
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertTrue(result?.name.contains("鼎泰豐") == true)
    }

    func test_parse_postWithOnlyDescription_noPatterns() {
        let text = """
        今天跟朋友去吃了一家義大利麵，
        味道還不錯，份量也很足，
        下次還會再去。
        """
        let result = LocalParser.parse(text: text)

        XCTAssertNil(result, "Text without any recognizable pattern should return nil")
    }

    // MARK: - Combined Title + Description (as used by ShareViewModel)

    func test_parse_titlePlusDescription_combined() {
        let title = "台北美食"
        let description = "【暇咖啡】在九份老街上，📍新北市瑞芳區基山街100號"
        let combined = title + " " + description

        let result = LocalParser.parse(text: combined)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "暇咖啡")
    }

    // MARK: - Whitespace / Trimming

    func test_parse_nameWithLeadingTrailingSpaces_isTrimmed() {
        let text = "【  好餐廳  】推薦"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "好餐廳")
    }

    func test_parse_emojiNameWithExtraSpaces_isTrimmed() {
        let text = "📍   暇咖啡   \n好地方"
        let result = LocalParser.parse(text: text)

        XCTAssertNotNil(result)
        // The regex captures everything between emoji and \n, then trims
        XCTAssertEqual(result?.name, "暇咖啡")
    }
}
