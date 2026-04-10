import SwiftData
import Foundation

@Model
final class HistoryEntry {
    var placeId: String
    var name: String
    var address: String
    var openedAt: Date

    init(placeId: String, name: String, address: String, openedAt: Date = .now) {
        self.placeId = placeId
        self.name = name
        self.address = address
        self.openedAt = openedAt
    }
}
