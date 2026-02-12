import SwiftUI

// MARK: - Tab 2: Stats / Competitions

struct CompetitionsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localization: LocalizationManager
    @State private var selectedCompId: Int? = nil  // nil = show first competition
    @State private var selectedSegment: CompSegment = .schedule

    enum CompSegment: String, CaseIterable {
        case schedule, standings, players, teams

        var title: String {
            switch self {
            case .schedule: return L10n.segSchedule
            case .standings: return L10n.segStandings
            case .players: return L10n.segPlayers
            case .teams: return L10n.segTeamsTab
            }
        }
    }

    private var compIconItems: [IconItem] {
        appState.selectedCompetitionIds.map { id in
            IconItem(
                id: id,
                name: appState.selectedCompetitionNames[id] ?? L10n.competitions,
                shortName: appState.selectedCompetitionNames[id]?.components(separatedBy: " ").first ?? "",
                imageURL: appState.selectedCompetitionEmblems[id]
            )
        }
    }

    /// The currently active competition ID (first selected if none tapped)
    private var activeCompId: Int? {
        if let id = selectedCompId { return id }
        return appState.selectedCompetitionIds.first
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if appState.selectedCompetitionIds.isEmpty {
                    EmptyStateView(
                        icon: "trophy",
                        title: L10n.noCompetitionsSelected,
                        message: L10n.noCompetitionsMessage
                    )
                } else {
                    // 1) Competition icon scroll bar (no "All" button)
                    IconScrollBar(items: compIconItems, selectedId: $selectedCompId, showAllButton: false)

                    // 2) Segment tab bar
                    SegmentTabBar(
                        tabs: CompSegment.allCases.map { ($0, $0.title) },
                        selected: $selectedSegment
                    )

                    // 3) Content for selected segment
                    if let compId = activeCompId {
                        switch selectedSegment {
                        case .schedule:
                            CompScheduleContent(competitionId: compId)
                        case .standings:
                            StandingsView(competitionId: compId)
                        case .players:
                            CompPlayersContent(competitionId: compId)
                        case .teams:
                            CompTeamsContent(competitionId: compId)
                        }
                    }
                }
            }
            .navigationTitle(L10n.competitions)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Competition Schedule Content

struct CompScheduleContent: View {
    let competitionId: Int
    @State private var matches: [Match] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(L10n.loadingSchedule)
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
        .id(competitionId) // Force refresh when competition changes
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
        let from = formatter.string(from: Calendar.current.date(byAdding: .day, value: -14, to: today)!)
        let to = formatter.string(from: Calendar.current.date(byAdding: .day, value: 30, to: today)!)
        do {
            let response = try await APIService.shared.fetchCompetitionMatches(
                competitionId: competitionId, dateFrom: from, dateTo: to
            )
            matches = response.matches.sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Standings View

struct StandingsView: View {
    let competitionId: Int
    @State private var standings: [StandingGroup] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedType: String = "TOTAL"

    var body: some View {
        Group {
            if isLoading {
                LoadingView(L10n.loadingStandings)
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadStandings() }
                }
            } else if standings.isEmpty {
                EmptyStateView(icon: "list.number", title: L10n.noData, message: L10n.noStandingsData)
            } else {
                standingsContent
            }
        }
        .task {
            if standings.isEmpty {
                await loadStandings()
            }
        }
        .id(competitionId)
    }

    private var currentStandings: StandingGroup? {
        standings.first { $0.type == selectedType }
    }

    private var standingsContent: some View {
        VStack(spacing: 0) {
            if standings.count > 1 && standings.contains(where: { $0.group == nil }) {
                Picker(L10n.type, selection: $selectedType) {
                    Text(L10n.standingTotal).tag("TOTAL")
                    Text(L10n.standingHome).tag("HOME")
                    Text(L10n.standingAway).tag("AWAY")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            let groupStandings = standings.filter { $0.group != nil }
            if !groupStandings.isEmpty {
                List {
                    ForEach(groupStandings) { group in
                        Section(header: Text(group.groupName)) {
                            standingsHeader
                            ForEach(group.table) { row in
                                StandingRowView(row: row)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            } else if let current = currentStandings {
                List {
                    Section {
                        standingsHeader
                        ForEach(current.table) { row in
                            StandingRowView(row: row)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var standingsHeader: some View {
        HStack(spacing: 0) {
            Text("#")
                .frame(width: 24, alignment: .center)
            Text(L10n.team)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
            Text(L10n.played)
                .frame(width: 28)
            Text(L10n.won)
                .frame(width: 28)
            Text(L10n.draw)
                .frame(width: 28)
            Text(L10n.lost)
                .frame(width: 28)
            Text(L10n.goalDiff)
                .frame(width: 34)
            Text(L10n.points)
                .frame(width: 34)
                .fontWeight(.semibold)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
    }

    private func loadStandings() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await APIService.shared.fetchStandings(competitionId: competitionId)
            standings = response.standings
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Standing Row

struct StandingRowView: View {
    let row: StandingRow

    var body: some View {
        HStack(spacing: 0) {
            Text("\(row.position)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(positionColor)
                .frame(width: 24, alignment: .center)

            HStack(spacing: 6) {
                CrestImage(row.team.crest, size: 20)
                Text(row.team.shortName ?? row.team.tla ?? row.team.name ?? "")
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4)

            Text("\(row.playedGames)")
                .frame(width: 28)
            Text("\(row.won)")
                .frame(width: 28)
            Text("\(row.draw)")
                .frame(width: 28)
            Text("\(row.lost)")
                .frame(width: 28)
            Text("\(row.goalDifference > 0 ? "+" : "")\(row.goalDifference)")
                .frame(width: 34)
            Text("\(row.points)")
                .fontWeight(.bold)
                .frame(width: 34)
        }
        .font(.caption)
        .padding(.vertical, 2)
    }

    private var positionColor: Color {
        switch row.position {
        case 1...4: return .green
        case 5...6: return .blue
        case 18...20: return .red
        default: return .primary
        }
    }
}

// MARK: - Competition Players (Scorers + Assists)

struct CompPlayersContent: View {
    let competitionId: Int
    @State private var showAssists = false

    var body: some View {
        VStack(spacing: 0) {
            Picker(L10n.type, selection: $showAssists) {
                Text(L10n.topScorers).tag(false)
                Text(L10n.topAssists).tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            ScorersListView(competitionId: competitionId, showAssists: showAssists)
        }
        .id(competitionId)
    }
}

// MARK: - Scorers List View

struct ScorersListView: View {
    let competitionId: Int
    let showAssists: Bool
    @State private var scorers: [Scorer] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(showAssists ? L10n.loadingAssists : L10n.loadingScorers)
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadScorers() }
                }
            } else if sortedScorers.isEmpty {
                EmptyStateView(
                    icon: showAssists ? "hand.point.up" : "soccerball",
                    title: L10n.noData,
                    message: showAssists ? L10n.noAssistsData : L10n.noScorersData
                )
            } else {
                List {
                    Section {
                        scorerHeader
                        ForEach(Array(sortedScorers.enumerated()), id: \.element.id) { index, scorer in
                            ScorerRowView(scorer: scorer, rank: index + 1, showAssists: showAssists)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            if scorers.isEmpty {
                await loadScorers()
            }
        }
    }

    private var sortedScorers: [Scorer] {
        if showAssists {
            return scorers
                .filter { ($0.assists ?? 0) > 0 }
                .sorted { ($0.assists ?? 0) > ($1.assists ?? 0) }
        }
        return scorers.sorted { ($0.goals ?? 0) > ($1.goals ?? 0) }
    }

    private var scorerHeader: some View {
        HStack(spacing: 0) {
            Text("#")
                .frame(width: 28, alignment: .center)
            Text(L10n.player)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.team)
                .frame(width: 50)
            Text(L10n.matchesPlayed)
                .frame(width: 36)
            if showAssists {
                Text(L10n.assists)
                    .frame(width: 36)
                    .fontWeight(.semibold)
            } else {
                Text(L10n.goals)
                    .frame(width: 36)
                    .fontWeight(.semibold)
                Text(L10n.assists)
                    .frame(width: 36)
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
    }

    private func loadScorers() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await APIService.shared.fetchScorers(competitionId: competitionId, limit: 30)
            scorers = response.scorers
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Scorer Row

struct ScorerRowView: View {
    let scorer: Scorer
    let rank: Int
    let showAssists: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(rank <= 3 ? .orange : .primary)
                .frame(width: 28, alignment: .center)

            VStack(alignment: .leading, spacing: 1) {
                Text(scorer.player.name)
                    .font(.caption)
                    .lineLimit(1)
                if let nationality = scorer.player.nationality {
                    Text(nationality)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(scorer.team?.tla ?? "")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 50)

            Text("\(scorer.playedMatches ?? 0)")
                .frame(width: 36)

            if showAssists {
                Text("\(scorer.assists ?? 0)")
                    .fontWeight(.bold)
                    .frame(width: 36)
            } else {
                Text("\(scorer.goals ?? 0)")
                    .fontWeight(.bold)
                    .frame(width: 36)
                Text("\(scorer.assists ?? 0)")
                    .frame(width: 36)
            }
        }
        .font(.caption)
        .padding(.vertical, 2)
    }
}

// MARK: - Competition Teams Content

struct CompTeamsContent: View {
    let competitionId: Int
    @State private var teams: [Team] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                LoadingView(L10n.loadingTeams)
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadTeams() }
                }
            } else if teams.isEmpty {
                EmptyStateView(icon: "person.3", title: L10n.noData, message: "")
            } else {
                List {
                    ForEach(teams) { team in
                        HStack(spacing: 12) {
                            CrestImage(team.crest, size: 30)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(team.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                if let venue = team.venue {
                                    Text(venue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            if teams.isEmpty {
                await loadTeams()
            }
        }
        .id(competitionId)
    }

    private func loadTeams() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await APIService.shared.fetchCompetitionTeams(competitionId: competitionId)
            teams = response.teams?.sorted { $0.name < $1.name } ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
