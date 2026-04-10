import SwiftData
import Foundation

@Model
final class RestaurantItem {
    var placeId: String
    var name: String
    var address: String
    var savedAt: Date
    var list: RestaurantList?

    init(placeId: String, name: String, address: String, savedAt: Date = .now) {
        self.placeId = placeId
        self.name = name
        self.address = address
        self.savedAt = savedAt
    }
}
