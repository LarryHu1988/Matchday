import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            ScheduleView()
                .tabItem {
                    Label("赛程", systemImage: "calendar")
                }

            CompetitionsView()
                .tabItem {
                    Label("赛事", systemImage: "trophy")
                }

            TeamsView()
                .tabItem {
                    Label("球队", systemImage: "person.3")
                }
        }
        .tint(.green)
    }
}
