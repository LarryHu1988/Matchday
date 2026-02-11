import SwiftUI

struct CompetitionsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        NavigationStack {
            if appState.selectedCompetitionIds.isEmpty {
                EmptyStateView(
                    icon: "trophy",
                    title: L10n.noCompetitionsSelected,
                    message: L10n.noCompetitionsMessage
                )
                .navigationTitle(L10n.competitions)
            } else {
                List {
                    ForEach(appState.selectedCompetitionIds, id: \.self) { compId in
                        let name = appState.selectedCompetitionNames[compId] ?? L10n.competitions
                        let emblem = appState.selectedCompetitionEmblems[compId]
                        NavigationLink(destination: CompetitionDetailView(competitionId: compId, competitionName: name)) {
                            HStack(spacing: 12) {
                                CrestImage(emblem, size: 30)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(name)
                                        .font(.headline)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
                .navigationTitle(L10n.competitions)
            }
        }
    }
}

// MARK: - Competition Detail View

struct CompetitionDetailView: View {
    let competitionId: Int
    let competitionName: String

    @State private var selectedTab: CompTab = .standings

    enum CompTab: String, CaseIterable {
        case standings = "standings"
        case scorers = "scorers"
        case assists = "assists"

        var title: String {
            switch self {
            case .standings: return L10n.standings
            case .scorers: return L10n.topScorers
            case .assists: return L10n.topAssists
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(L10n.options, selection: $selectedTab) {
                ForEach(CompTab.allCases, id: \.self) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedTab {
            case .standings:
                StandingsView(competitionId: competitionId)
            case .scorers:
                ScorersListView(competitionId: competitionId, showAssists: false)
            case .assists:
                ScorersListView(competitionId: competitionId, showAssists: true)
            }
        }
        .navigationTitle(competitionName)
        .navigationBarTitleDisplayMode(.inline)
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
    }

    private var currentStandings: StandingGroup? {
        standings.first { $0.type == selectedType }
    }

    private var standingsContent: some View {
        VStack(spacing: 0) {
            // Type selector (TOTAL/HOME/AWAY) if multiple types
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

            // Handle group stages
            let groupStandings = standings.filter { $0.group != nil }
            if !groupStandings.isEmpty {
                // Group stage - show each group
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
