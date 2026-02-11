import SwiftUI

@main
struct MatchdayApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var localization = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(localization)
            } else {
                OnboardingView()
                    .environmentObject(appState)
                    .environmentObject(localization)
            }
        }
    }
}
