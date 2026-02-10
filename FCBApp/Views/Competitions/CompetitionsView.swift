import SwiftUI

struct CompetitionsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            if appState.selectedCompetitionIds.isEmpty {
                EmptyStateView(
                    icon: "trophy",
                    title: "未选择赛事",
                    message: "请在球队页面的设置中添加要关注的赛事"
                )
                .navigationTitle("赛事")
            } else {
                List {
                    ForEach(appState.selectedCompetitionIds, id: \.self) { compId in
                        let name = appState.selectedCompetitionNames[compId] ?? "赛事"
                        NavigationLink(destination: CompetitionDetailView(competitionId: compId, competitionName: name)) {
                            HStack(spacing: 12) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.orange)
                                    .frame(width: 30)
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
                .navigationTitle("赛事")
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
            case .standings: return "积分榜"
            case .scorers: return "射手榜"
            case .assists: return "助攻榜"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("选项", selection: $selectedTab) {
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
                LoadingView("加载积分榜...")
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadStandings() }
                }
            } else if standings.isEmpty {
                EmptyStateView(icon: "list.number", title: "暂无数据", message: "该赛事暂无积分榜数据")
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
                Picker("类型", selection: $selectedType) {
                    Text("总榜").tag("TOTAL")
                    Text("主场").tag("HOME")
                    Text("客场").tag("AWAY")
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
            Text("球队")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
            Text("赛")
                .frame(width: 28)
            Text("胜")
                .frame(width: 28)
            Text("平")
                .frame(width: 28)
            Text("负")
                .frame(width: 28)
            Text("净胜")
                .frame(width: 34)
            Text("积分")
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
                LoadingView(showAssists ? "加载助攻榜..." : "加载射手榜...")
            } else if let error = errorMessage {
                ErrorView(message: error) {
                    Task { await loadScorers() }
                }
            } else if sortedScorers.isEmpty {
                EmptyStateView(
                    icon: showAssists ? "hand.point.up" : "soccerball",
                    title: "暂无数据",
                    message: showAssists ? "该赛事暂无助攻数据" : "该赛事暂无射手数据"
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
            Text("球员")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("球队")
                .frame(width: 50)
            Text("场次")
                .frame(width: 36)
            if showAssists {
                Text("助攻")
                    .frame(width: 36)
                    .fontWeight(.semibold)
            } else {
                Text("进球")
                    .frame(width: 36)
                    .fontWeight(.semibold)
                Text("助攻")
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
