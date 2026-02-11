import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localization: LocalizationManager
    @State private var showAddSheet = false
    @State private var apiKeyInput = ""

    var body: some View {
        List {
            // Language
            Section(L10n.language) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    HStack {
                        Text(lang.displayName)
                            .font(.subheadline)
                        Spacer()
                        if localization.language == lang {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.green)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        localization.language = lang
                    }
                }
            }

            // API Key
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField(L10n.enterApiKey, text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Text(L10n.apiKeyHint)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text(L10n.apiConfig)
            } footer: {
                if !apiKeyInput.isEmpty {
                    Button(L10n.save) {
                        appState.apiKey = apiKeyInput
                    }
                    .font(.subheadline)
                }
            }

            // Selected Teams
            Section(L10n.selectedTeamsSection(appState.selectedTeamIds.count)) {
                if appState.selectedTeamIds.isEmpty {
                    Text(L10n.noTeamsSelectedShort)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.selectedTeamIds, id: \.self) { teamId in
                        HStack {
                            CrestImage(appState.selectedTeamCrests[teamId], size: 22)
                            Text(appState.selectedTeamNames[teamId] ?? L10n.teamFallback(teamId))
                                .font(.subheadline)
                            Spacer()
                            Button {
                                appState.removeTeam(id: teamId)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }

            // Selected Competitions
            Section(L10n.selectedCompetitionsSection(appState.selectedCompetitionIds.count)) {
                if appState.selectedCompetitionIds.isEmpty {
                    Text(L10n.noCompetitionsSelectedShort)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.selectedCompetitionIds, id: \.self) { compId in
                        HStack {
                            CrestImage(appState.selectedCompetitionEmblems[compId], size: 22)
                            Text(appState.selectedCompetitionNames[compId] ?? L10n.competitionFallback(compId))
                                .font(.subheadline)
                            Spacer()
                            Button {
                                appState.removeCompetition(id: compId)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }

            // Add button
            if appState.canAddMore {
                Section {
                    Button {
                        showAddSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(L10n.addTeamOrCompetition)
                            Spacer()
                            Text(L10n.remainingSlots(appState.remainingSlots))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Selection count
            Section {
                HStack {
                    Text(L10n.selected)
                    Spacer()
                    Text("\(appState.totalSelections) / 10")
                        .fontWeight(.semibold)
                        .foregroundStyle(appState.totalSelections >= 10 ? .red : .green)
                }
            } footer: {
                Text(L10n.maxSelections)
            }

            // Reset
            Section {
                Button(role: .destructive) {
                    appState.resetOnboarding()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text(L10n.resetAll)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(L10n.settings)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSheet) {
            AddSelectionSheet()
        }
        .onAppear {
            apiKeyInput = appState.apiKey
        }
    }
}

// MARK: - Add Selection Sheet

struct AddSelectionSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var competitions: [Competition] = []
    @State private var teams: [Team] = []
    @State private var isLoadingCompetitions = false
    @State private var isLoadingTeams = false
    @State private var selectedCompetitionForTeams: Competition?
    @State private var searchText = ""
    @State private var mode: AddMode = .competition

    enum AddMode: String, CaseIterable {
        case competition = "competition"
        case team = "team"

        var title: String {
            switch self {
            case .competition: return L10n.competitionMode
            case .team: return L10n.teamMode
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker(L10n.type, selection: $mode) {
                    ForEach(AddMode.allCases, id: \.self) { m in
                        Text(m.title).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch mode {
                case .competition:
                    competitionsList
                case .team:
                    teamsSelection
                }
            }
            .navigationTitle(L10n.addFollowing)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.done) { dismiss() }
                }
            }
        }
    }

    // MARK: - Competitions List

    private var competitionsList: some View {
        Group {
            if isLoadingCompetitions {
                LoadingView(L10n.loadingCompetitions)
            } else {
                List {
                    ForEach(filteredCompetitions) { comp in
                        HStack {
                            CrestImage(comp.emblem, size: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(comp.name)
                                    .font(.subheadline)
                                if let area = comp.area {
                                    Text(area.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if appState.isCompetitionSelected(comp.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if appState.canAddMore {
                                Button {
                                    appState.addCompetition(id: comp.id, name: comp.name, emblem: comp.emblem)
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: L10n.searchCompetitions)
            }
        }
        .task {
            if competitions.isEmpty {
                await loadCompetitions()
            }
        }
    }

    private var filteredCompetitions: [Competition] {
        if searchText.isEmpty { return competitions }
        return competitions.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.area?.name.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // MARK: - Teams Selection

    private var teamsSelection: some View {
        VStack(spacing: 0) {
            if selectedCompetitionForTeams == nil {
                // Step 1: Pick a competition to browse teams from
                Text(L10n.selectCompetitionFirst)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()

                if isLoadingCompetitions {
                    LoadingView()
                } else {
                    List {
                        ForEach(competitions) { comp in
                            Button {
                                selectedCompetitionForTeams = comp
                                Task { await loadTeams(competitionId: comp.id) }
                            } label: {
                                HStack {
                                    CrestImage(comp.emblem, size: 20)
                                    Text(comp.name)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                // Step 2: Show teams from selected competition
                HStack {
                    Button {
                        selectedCompetitionForTeams = nil
                        teams = []
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(L10n.back)
                        }
                        .font(.subheadline)
                    }
                    Spacer()
                    Text(selectedCompetitionForTeams?.name ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                if isLoadingTeams {
                    LoadingView(L10n.loadingTeams)
                } else {
                    List {
                        ForEach(filteredTeams) { team in
                            HStack {
                                CrestImage(team.crest, size: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.name)
                                        .font(.subheadline)
                                    if let venue = team.venue {
                                        Text(venue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if appState.isTeamSelected(team.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if appState.canAddMore {
                                    Button {
                                        appState.addTeam(id: team.id, name: team.shortName ?? team.name, crest: team.crest)
                                    } label: {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: L10n.searchTeams)
                }
            }
        }
        .task {
            if competitions.isEmpty {
                await loadCompetitions()
            }
        }
    }

    private var filteredTeams: [Team] {
        if searchText.isEmpty { return teams }
        return teams.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.shortName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // MARK: - Data Loading

    private func loadCompetitions() async {
        isLoadingCompetitions = true
        do {
            competitions = try await APIService.shared.fetchCompetitions()
            // Filter to free tier competitions
            let freeCodes = Set(["PL", "BL1", "PD", "SA", "FL1", "ELC", "DED", "PPL", "BSA", "CL", "WC", "EC"])
            competitions = competitions.filter { freeCodes.contains($0.code ?? "") }
        } catch {
            print("Failed to load competitions: \(error)")
        }
        isLoadingCompetitions = false
    }

    private func loadTeams(competitionId: Int) async {
        isLoadingTeams = true
        do {
            let response = try await APIService.shared.fetchCompetitionTeams(competitionId: competitionId)
            teams = response.teams ?? []
        } catch {
            print("Failed to load teams: \(error)")
        }
        isLoadingTeams = false
    }
}
