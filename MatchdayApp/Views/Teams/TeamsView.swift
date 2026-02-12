import SwiftUI

// MARK: - Tab 3: Teams

struct TeamsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localization: LocalizationManager
    @State private var selectedTeamId: Int? = nil  // nil = show first team
    @State private var selectedSegment: TeamSegment = .squad

    enum TeamSegment: String, CaseIterable {
        case squad, stats, info

        var title: String {
            switch self {
            case .squad: return L10n.segSquad
            case .stats: return L10n.segStats
            case .info: return L10n.segInfo
            }
        }
    }

    private var teamIconItems: [IconItem] {
        appState.selectedTeamIds.map { id in
            IconItem(
                id: id,
                name: appState.selectedTeamNames[id] ?? L10n.teams,
                shortName: appState.selectedTeamNames[id]?.components(separatedBy: " ").first ?? "",
                imageURL: appState.selectedTeamCrests[id]
            )
        }
    }

    /// The currently active team ID (first selected if none tapped)
    private var activeTeamId: Int? {
        if let id = selectedTeamId { return id }
        return appState.selectedTeamIds.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if appState.selectedTeamIds.isEmpty {
                    EmptyStateView(
                        icon: "person.3",
                        title: L10n.noTeamsSelected,
                        message: L10n.noTeamsMessage
                    )
                } else {
                    // 1) Team crest scroll bar (no "All" button)
                    IconScrollBar(items: teamIconItems, selectedId: $selectedTeamId, showAllButton: false)

                    // 2) Segment tab bar
                    SegmentTabBar(
                        tabs: TeamSegment.allCases.map { ($0, $0.title) },
                        selected: $selectedSegment
                    )

                    // 3) Content for selected segment
                    if let teamId = activeTeamId {
                        switch selectedSegment {
                        case .squad:
                            TeamSquadContent(teamId: teamId)
                                .id(teamId)
                        case .stats:
                            TeamStatsContent(teamId: teamId)
                                .id(teamId)
                        case .info:
                            TeamInfoContent(teamId: teamId)
                                .id(teamId)
                        }
                    }
                }
            }
            .navigationTitle(L10n.teams)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    settingsButton
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

// MARK: - Team Matches Tab

struct TeamMatchesTab: View {
    let teamId: Int
    @State private var matches: [Match] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(L10n.loadingMatches)
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadMatches() }
                }
            } else if matches.isEmpty {
                EmptyStateView(icon: "calendar", title: L10n.noSchedule, message: L10n.noMatchesScheduled)
            } else {
                matchList
            }
        }
        .task {
            if matches.isEmpty {
                await loadMatches()
            }
        }
    }

    private var groupedMatches: [(String, [Match])] {
        let grouped = Dictionary(grouping: matches) { $0.dateText }
        return grouped.sorted { a, b in
            let dateA = matches.first { $0.dateText == a.key }?.date ?? .distantPast
            let dateB = matches.first { $0.dateText == b.key }?.date ?? .distantPast
            return dateA < dateB
        }
    }

    private var matchList: some View {
        List {
            ForEach(groupedMatches, id: \.0) { dateString, dayMatches in
                Section {
                    ForEach(dayMatches) { match in
                        MatchRow(match: match)
                    }
                } header: {
                    Text(dateString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.plain)
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

// MARK: - Team Squad Content

struct TeamSquadContent: View {
    let teamId: Int
    @State private var team: Team?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(L10n.loadingTeam)
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadTeam() }
                }
            } else if let team = team {
                TeamSquadTab(team: team)
            } else {
                EmptyStateView(icon: "person.3", title: L10n.noData, message: "")
            }
        }
        .task {
            if team == nil { await loadTeam() }
        }
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

// MARK: - Team Stats Content

struct TeamStatsContent: View {
    let teamId: Int
    @State private var team: Team?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(L10n.loadingTeam)
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadTeam() }
                }
            } else if let team = team {
                teamStatsView(team)
            } else {
                EmptyStateView(icon: "chart.bar", title: L10n.noData, message: "")
            }
        }
        .task {
            if team == nil { await loadTeam() }
        }
    }

    private func teamStatsView(_ team: Team) -> some View {
        List {
            if let squad = team.squad, !squad.isEmpty {
                // Quick summary stats
                Section(L10n.segStats) {
                    InfoRow(label: L10n.segSquad, value: "\(squad.count)")

                    let gkCount = squad.filter { $0.position == "Goalkeeper" }.count
                    let defCount = squad.filter { $0.position == "Defence" }.count
                    let midCount = squad.filter { $0.position == "Midfield" }.count
                    let fwdCount = squad.filter { $0.position == "Offence" }.count

                    InfoRow(label: L10n.posGoalkeeper, value: "\(gkCount)")
                    InfoRow(label: L10n.posDefence, value: "\(defCount)")
                    InfoRow(label: L10n.posMidfield, value: "\(midCount)")
                    InfoRow(label: L10n.posForward, value: "\(fwdCount)")
                }

                // Nationality breakdown
                let nationalities = Dictionary(grouping: squad) { $0.nationality ?? L10n.other }
                    .mapValues { $0.count }
                    .sorted { $0.value > $1.value }

                Section(L10n.nationality) {
                    ForEach(nationalities, id: \.key) { nationality, count in
                        InfoRow(label: nationality, value: "\(count)")
                    }
                }
            }

            // Running competitions
            if let comps = team.runningCompetitions, !comps.isEmpty {
                Section(L10n.runningCompetitions) {
                    ForEach(comps, id: \.id) { comp in
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

// MARK: - Team Info Content

struct TeamInfoContent: View {
    let teamId: Int
    @State private var team: Team?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(L10n.loadingTeam)
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadTeam() }
                }
            } else if let team = team {
                TeamOverviewTab(team: team)
            } else {
                EmptyStateView(icon: "info.circle", title: L10n.noData, message: "")
            }
        }
        .task {
            if team == nil { await loadTeam() }
        }
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

// MARK: - Team Overview Tab (Info section)

struct TeamOverviewTab: View {
    let team: Team

    var body: some View {
        List {
            // Basic Info
            Section(L10n.basicInfo) {
                if let founded = team.founded {
                    InfoRow(label: L10n.founded, value: "\(founded)")
                }
                if let colors = team.clubColors {
                    InfoRow(label: L10n.clubColors, value: colors)
                }
                if let address = team.address {
                    InfoRow(label: L10n.address, value: address)
                }
                if let website = team.website {
                    InfoRow(label: L10n.website, value: website)
                }
                if let venue = team.venue {
                    InfoRow(label: "Stadium", value: venue)
                }
            }

            // Coach
            if let coach = team.coach {
                Section(L10n.headCoach) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(coach.name ?? "\(coach.firstName ?? "") \(coach.lastName ?? "")")
                            .font(.headline)
                        if let nationality = coach.nationality {
                            InfoRow(label: L10n.nationality, value: nationality)
                        }
                        if let dob = coach.dateOfBirth {
                            InfoRow(label: L10n.dateOfBirth, value: dob)
                        }
                        if let contract = coach.contract {
                            if let until = contract.until {
                                InfoRow(label: L10n.contractUntil, value: until)
                            }
                        }
                    }
                }
            }

            // Competitions
            if let competitions = team.runningCompetitions, !competitions.isEmpty {
                Section(L10n.runningCompetitions) {
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
                Section(L10n.posGoalkeeper) {
                    ForEach(goalkeepers) { PlayerRow(player: $0) }
                }
            }
            if !defenders.isEmpty {
                Section(L10n.posDefence) {
                    ForEach(defenders) { PlayerRow(player: $0) }
                }
            }
            if !midfielders.isEmpty {
                Section(L10n.posMidfield) {
                    ForEach(midfielders) { PlayerRow(player: $0) }
                }
            }
            if !forwards.isEmpty {
                Section(L10n.posForward) {
                    ForEach(forwards) { PlayerRow(player: $0) }
                }
            }
            if !others.isEmpty {
                Section(L10n.other) {
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
                        Text(L10n.ageYears(age))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Text(player.positionLabel)
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
