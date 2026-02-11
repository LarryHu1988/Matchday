import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localization: LocalizationManager
    @State private var matches: [Match] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedFilter: ScheduleFilter = .upcoming

    enum ScheduleFilter: String, CaseIterable {
        case upcoming = "upcoming"
        case results = "results"
        case all = "all"

        var title: String {
            switch self {
            case .upcoming: return L10n.scheduleUpcoming
            case .results: return L10n.scheduleResults
            case .all: return L10n.scheduleAll
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker(L10n.filter, selection: $selectedFilter) {
                    ForEach(ScheduleFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if isLoading {
                    LoadingView(L10n.loadingSchedule)
                } else if let error = errorMessage {
                    ErrorView(message: error) {
                        Task { await loadMatches() }
                    }
                } else if filteredMatches.isEmpty {
                    EmptyStateView(
                        icon: "sportscourt",
                        title: L10n.noSchedule,
                        message: L10n.noScheduleMessage
                    )
                } else {
                    matchList
                }
            }
            .navigationTitle(L10n.schedule)
            .refreshable {
                await loadMatches()
            }
            .task {
                if matches.isEmpty {
                    await loadMatches()
                }
            }
            .onChange(of: selectedFilter) { _, _ in }
        }
    }

    private var filteredMatches: [Match] {
        switch selectedFilter {
        case .upcoming:
            return matches.filter { $0.isScheduled || $0.isLive }
        case .results:
            return matches.filter { $0.isFinished }.reversed()
        case .all:
            return matches
        }
    }

    private var groupedMatches: [(String, [Match])] {
        let grouped = Dictionary(grouping: filteredMatches) { match in
            match.dateText
        }
        return grouped.sorted { a, b in
            let dateA = filteredMatches.first { $0.dateText == a.key }?.date ?? .distantPast
            let dateB = filteredMatches.first { $0.dateText == b.key }?.date ?? .distantPast
            return selectedFilter == .results ? dateA > dateB : dateA < dateB
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

        do {
            var allMatches: [Match] = []

            // Load matches for selected teams
            for teamId in appState.selectedTeamIds {
                let from = formatter.string(from: Calendar.current.date(byAdding: .day, value: -30, to: today)!)
                let to = formatter.string(from: Calendar.current.date(byAdding: .day, value: 60, to: today)!)
                let response = try await APIService.shared.fetchTeamMatches(
                    teamId: teamId, dateFrom: from, dateTo: to
                )
                allMatches.append(contentsOf: response.matches)
            }

            // Load matches for selected competitions
            for compId in appState.selectedCompetitionIds {
                let from = formatter.string(from: Calendar.current.date(byAdding: .day, value: -14, to: today)!)
                let to = formatter.string(from: Calendar.current.date(byAdding: .day, value: 30, to: today)!)
                let response = try await APIService.shared.fetchCompetitionMatches(
                    competitionId: compId, dateFrom: from, dateTo: to
                )
                allMatches.append(contentsOf: response.matches)
            }

            // Deduplicate by match ID and sort by date
            let unique = Dictionary(grouping: allMatches, by: \.id)
                .compactMap { $0.value.first }
                .sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }

            matches = unique
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Match Row

struct MatchRow: View {
    let match: Match

    var body: some View {
        VStack(spacing: 8) {
            // Competition name
            if let comp = match.competition {
                HStack {
                    CrestImage(comp.emblem, size: 14)
                    Text(comp.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if let matchday = match.matchday {
                        Text(L10n.matchdayRound(matchday))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Teams and score
            HStack {
                // Home team
                HStack(spacing: 8) {
                    Spacer()
                    Text(match.homeTeam.shortName ?? match.homeTeam.name ?? L10n.homeTeam)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    CrestImage(match.homeTeam.crest, size: 24)
                }
                .frame(maxWidth: .infinity)

                // Score / Time
                VStack(spacing: 2) {
                    if match.isFinished || match.isLive {
                        Text(match.scoreText)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(match.isLive ? .red : .primary)
                    } else {
                        Text(match.timeText)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    Text(match.statusText)
                        .font(.caption2)
                        .foregroundStyle(match.isLive ? .red : .secondary)
                }
                .frame(width: 70)

                // Away team
                HStack(spacing: 8) {
                    CrestImage(match.awayTeam.crest, size: 24)
                    Text(match.awayTeam.shortName ?? match.awayTeam.name ?? L10n.awayTeam)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 4)
    }
}
