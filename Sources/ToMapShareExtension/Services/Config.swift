import Foundation

enum Config {
    static let groqAPIKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GROQ_API_KEY") as? String, !key.isEmpty else {
            fatalError("GROQ_API_KEY not set. Copy Config.xcconfig.example to Config.xcconfig and fill in your API keys.")
        }
        return key
    }()

    static let googlePlacesAPIKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String, !key.isEmpty else {
            fatalError("GOOGLE_PLACES_API_KEY not set. Copy Config.xcconfig.example to Config.xcconfig and fill in your API keys.")
        }
        return key
    }()
}
