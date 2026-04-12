import Foundation
import SwiftData

enum ShareState {
    case loading
    case confirmation(Place)
    case selection([Place])
    case error(String)
}

@MainActor
final class ShareViewModel: ObservableObject {
    @Published var state: ShareState = .loading

    private lazy var container: ModelContainer = PersistenceController.makeContainer()

    var modelContainer: ModelContainer { container }

    private let usageDefaults = UserDefaults(suiteName: "group.com.smt.tomap")!
    private let dailyLimit = 15

    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func todayUsageCount() -> Int {
        let saved = usageDefaults.string(forKey: "lastShareDate") ?? ""
        if saved != todayString {
            usageDefaults.set(0, forKey: "dailyShareCount")
            usageDefaults.set(todayString, forKey: "lastShareDate")
        }
        return usageDefaults.integer(forKey: "dailyShareCount")
    }

    private func incrementUsage() {
        usageDefaults.set(usageDefaults.integer(forKey: "dailyShareCount") + 1, forKey: "dailyShareCount")
    }

    func process(url: URL) {
        guard todayUsageCount() < dailyLimit else {
            state = .error("今日使用次數已達上限（15次），請明天再試。")
            return
        }
        incrementUsage()
        Task {
            do {
                print("[ToMap] Step 1: Fetching OG metadata from \(url)")
                let metadata = try await OGMetadataService.fetch(url: url)
                print("[ToMap] Step 1 OK - title: \(metadata.title)")
                print("[ToMap] Step 1 OK - description: \(metadata.description)")

                // Step 2a: 先嘗試本地快速解析（不消耗 API 配額）
                let text = metadata.title + " " + metadata.description
                let parsedList: [ParsedRestaurant]
                if let local = LocalParser.parse(text: text) {
                    print("[ToMap] Step 2 OK (local) - name: \(local.name), location: \(local.location)")
                    parsedList = [local]
                } else {
                    // Step 2b: Fallback 到 Groq
                    print("[ToMap] Step 2: Calling Groq API")
                    parsedList = try await GroqService.parseRestaurant(
                        title: metadata.title,
                        description: metadata.description
                    )
                    parsedList.forEach { print("[ToMap] Step 2 OK (Gemini) - name: \($0.name), location: \($0.location)") }
                }

                print("[ToMap] Step 3: Searching Google Places for \(parsedList.count) restaurant(s)")
                let allPlaces: [Place]
                if parsedList.count == 1 {
                    // 單一餐廳：沿用原有邏輯，可回傳多筆候選供使用者選
                    allPlaces = try await PlacesService.search(
                        name: parsedList[0].name,
                        location: parsedList[0].location
                    )
                } else {
                    // 多間餐廳：並行搜尋，每間取最佳一筆
                    allPlaces = try await withThrowingTaskGroup(of: Place?.self) { group in
                        for parsed in parsedList {
                            group.addTask {
                                let results = try await PlacesService.search(name: parsed.name, location: parsed.location)
                                return results.first
                            }
                        }
                        var collected: [Place] = []
                        for try await place in group {
                            if let place { collected.append(place) }
                        }
                        return collected
                    }
                }
                print("[ToMap] Step 3 OK - found \(allPlaces.count) place(s)")
                allPlaces.forEach { print("[ToMap]   • \($0.name) | \($0.address) | \($0.id)") }

                switch allPlaces.count {
                case 0:
                    state = .error("找不到餐廳資訊")
                case 1:
                    state = .confirmation(allPlaces[0])
                default:
                    state = .selection(allPlaces)
                }
            } catch GroqError.noRestaurantFound {
                print("[ToMap] Gemini: 無法辨識出餐廳名稱")
                state = .error("無法從此影片辨識出餐廳")
            } catch GroqError.requestFailed {
                print("[ToMap] Gemini: API 請求失敗（可能是配額超限）")
                state = .error("AI 解析失敗，請稍後再試\n（Gemini API 配額可能已用盡）")
            } catch {
                print("[ToMap] Error: \(error)")
                state = .error("找不到餐廳資訊")
            }
        }
    }

    func saveHistory(_ place: Place) {
        let context = ModelContext(container)
        context.insert(HistoryEntry(placeId: place.id, name: place.name, address: place.address))
        try? context.save()
    }

    func saveToList(_ place: Place, list: RestaurantList) {
        let context = ModelContext(container)
        let item = RestaurantItem(placeId: place.id, name: place.name, address: place.address)
        item.list = list
        context.insert(item)
        try? context.save()
    }

    func saveToNewList(_ place: Place, name: String) {
        let context = ModelContext(container)
        let list = RestaurantList(name: name)
        context.insert(list)
        let item = RestaurantItem(placeId: place.id, name: place.name, address: place.address)
        item.list = list
        context.insert(item)
        try? context.save()
    }

    func saveAllToNewList(_ places: [Place], name: String) {
        let context = ModelContext(container)
        let list = RestaurantList(name: name)
        context.insert(list)
        for place in places {
            let item = RestaurantItem(placeId: place.id, name: place.name, address: place.address)
            item.list = list
            context.insert(item)
        }
        try? context.save()
    }
}
