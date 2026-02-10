import SwiftUI

struct TeamsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            if appState.selectedTeamIds.isEmpty {
                EmptyStateView(
                    icon: "person.3",
                    title: "未选择球队",
                    message: "请在设置中添加要关注的球队"
                )
                .navigationTitle("球队")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        settingsButton
                    }
                }
            } else {
                List {
                    ForEach(appState.selectedTeamIds, id: \.self) { teamId in
                        let name = appState.selectedTeamNames[teamId] ?? "球队"
                        NavigationLink(destination: TeamDetailView(teamId: teamId)) {
                            HStack(spacing: 12) {
                                Image(systemName: "shield.fill")
                                    .foregroundStyle(.green)
                                    .frame(width: 30)
                                Text(name)
                                    .font(.headline)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle("球队")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        settingsButton
                    }
                }
            }
        }
    }

    private var settingsButton: some View {
        NavigationLink(destination: SettingsView()) {
            Image(systemName: "gearshape")
        }
    }
}

// MARK: - Team Detail View

struct TeamDetailView: View {
    let teamId: Int
    @State private var team: Team?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab: TeamTab = .overview

    enum TeamTab: String, CaseIterable {
        case overview = "overview"
        case squad = "squad"
        case matches = "matches"

        var title: String {
            switch self {
            case .overview: return "概览"
            case .squad: return "阵容"
            case .matches: return "赛程"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                LoadingView("加载球队信息...")
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadTeam() }
                }
            } else if let team = team {
                // Team header
                teamHeader(team)

                // Tab selector
                Picker("选项", selection: $selectedTab) {
                    ForEach(TeamTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Tab content
                switch selectedTab {
                case .overview:
                    TeamOverviewTab(team: team)
                case .squad:
                    TeamSquadTab(team: team)
                case .matches:
                    TeamMatchesTab(teamId: teamId)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if team == nil {
                await loadTeam()
            }
        }
    }

    private func teamHeader(_ team: Team) -> some View {
        VStack(spacing: 8) {
            CrestImage(team.crest, size: 60)
            Text(team.name)
                .font(.title3)
                .fontWeight(.bold)
            if let venue = team.venue {
                Text(venue)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func loadTeam() async {
        isLoading = true
        errorMessage = nil
        do {
            team = try await APIService.shared.fetchTeam(id: teamId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Overview Tab

struct TeamOverviewTab: View {
    let team: Team

    var body: some View {
        List {
            // Basic Info
            Section("基本信息") {
                if let founded = team.founded {
                    InfoRow(label: "成立年份", value: "\(founded)")
                }
                if let colors = team.clubColors {
                    InfoRow(label: "队色", value: colors)
                }
                if let address = team.address {
                    InfoRow(label: "地址", value: address)
                }
                if let website = team.website {
                    InfoRow(label: "官网", value: website)
                }
            }

            // Coach
            if let coach = team.coach {
                Section("主教练") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(coach.name ?? "\(coach.firstName ?? "") \(coach.lastName ?? "")")
                            .font(.headline)
                        if let nationality = coach.nationality {
                            InfoRow(label: "国籍", value: nationality)
                        }
                        if let dob = coach.dateOfBirth {
                            InfoRow(label: "出生日期", value: dob)
                        }
                        if let contract = coach.contract {
                            if let until = contract.until {
                                InfoRow(label: "合同到期", value: until)
                            }
                        }
                    }
                }
            }

            // Competitions
            if let competitions = team.runningCompetitions, !competitions.isEmpty {
                Section("参加赛事") {
                    ForEach(competitions, id: \.id) { comp in
                        HStack(spacing: 8) {
                            CrestImage(comp.emblem, size: 20)
                            Text(comp.name)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Squad Tab

struct TeamSquadTab: View {
    let team: Team

    private var goalkeepers: [Player] { team.squad?.filter { $0.position == "Goalkeeper" } ?? [] }
    private var defenders: [Player] { team.squad?.filter { $0.position == "Defence" } ?? [] }
    private var midfielders: [Player] { team.squad?.filter { $0.position == "Midfield" } ?? [] }
    private var forwards: [Player] { team.squad?.filter { $0.position == "Offence" } ?? [] }
    private var others: [Player] { team.squad?.filter { $0.position == nil || !["Goalkeeper", "Defence", "Midfield", "Offence"].contains($0.position!) } ?? [] }

    var body: some View {
        List {
            if !goalkeepers.isEmpty {
                Section("门将") {
                    ForEach(goalkeepers) { PlayerRow(player: $0) }
                }
            }
            if !defenders.isEmpty {
                Section("后卫") {
                    ForEach(defenders) { PlayerRow(player: $0) }
                }
            }
            if !midfielders.isEmpty {
                Section("中场") {
                    ForEach(midfielders) { PlayerRow(player: $0) }
                }
            }
            if !forwards.isEmpty {
                Section("前锋") {
                    ForEach(forwards) { PlayerRow(player: $0) }
                }
            }
            if !others.isEmpty {
                Section("其他") {
                    ForEach(others) { PlayerRow(player: $0) }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Player Row

struct PlayerRow: View {
    let player: Player

    var body: some View {
        HStack(spacing: 12) {
            // Shirt number
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(player.shirtNumber.map { "\($0)" } ?? "-")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(player.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 8) {
                    if let nationality = player.nationality {
                        Text(nationality)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let age = player.age {
                        Text("\(age)岁")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(player.positionCN)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(positionColor.opacity(0.12))
                .foregroundStyle(positionColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }

    private var positionColor: Color {
        switch player.position {
        case "Goalkeeper": return .orange
        case "Defence": return .blue
        case "Midfield": return .green
        case "Offence": return .red
        default: return .gray
        }
    }
}

// MARK: - Team Matches Tab

struct TeamMatchesTab: View {
    let teamId: Int
    @State private var matches: [Match] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView("加载赛程...")
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadMatches() }
                }
            } else if matches.isEmpty {
                EmptyStateView(icon: "calendar", title: "暂无赛程", message: "暂无赛程安排")
            } else {
                List {
                    ForEach(matches) { match in
                        MatchRow(match: match)
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            if matches.isEmpty {
                await loadMatches()
            }
        }
    }

    private func loadMatches() async {
        isLoading = true
        errorMessage = nil
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let from = formatter.string(from: Calendar.current.date(byAdding: .day, value: -30, to: today)!)
        let to = formatter.string(from: Calendar.current.date(byAdding: .day, value: 60, to: today)!)
        do {
            let response = try await APIService.shared.fetchTeamMatches(teamId: teamId, dateFrom: from, dateTo: to)
            matches = response.matches
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Info Row Helper

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }
}
