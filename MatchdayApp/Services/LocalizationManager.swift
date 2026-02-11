import SwiftUI

// MARK: - App Language

enum AppLanguage: String, CaseIterable, Sendable {
    case chinese = "zh"
    case english = "en"

    var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        }
    }

    /// Thread-safe current language from UserDefaults
    static var current: AppLanguage {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "zh"
        return AppLanguage(rawValue: saved) ?? .chinese
    }
}

// MARK: - Localization Manager

@MainActor
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "zh"
        self.language = AppLanguage(rawValue: saved) ?? .chinese
    }
}
