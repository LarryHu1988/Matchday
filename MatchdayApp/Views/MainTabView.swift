import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        TabView {
            ScheduleView()
                .tabItem {
                    Label(L10n.tabKickoff, systemImage: "calendar")
                }

            CompetitionsView()
                .tabItem {
                    Label(L10n.tabStats, systemImage: "trophy")
                }

            TeamsView()
                .tabItem {
                    Label(L10n.tabTeams, systemImage: "person.3")
                }
        }
        .tint(.green)
    }
}
