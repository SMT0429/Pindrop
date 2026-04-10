import SwiftData
import Foundation

@Model
final class RestaurantList {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \RestaurantItem.list)
    var items: [RestaurantItem] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}
