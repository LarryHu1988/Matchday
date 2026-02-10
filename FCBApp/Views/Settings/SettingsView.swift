import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddSheet = false
    @State private var apiKeyInput = ""

    var body: some View {
        List {
            // API Key
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("输入Football-Data.org API Key", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Text("在 football-data.org 免费注册获取")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("API 配置")
            } footer: {
                if !apiKeyInput.isEmpty {
                    Button("保存") {
                        appState.apiKey = apiKeyInput
                    }
                    .font(.subheadline)
                }
            }

            // Selected Teams
            Section("已选球队 (\(appState.selectedTeamIds.count))") {
                if appState.selectedTeamIds.isEmpty {
                    Text("未选择球队")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.selectedTeamIds, id: \.self) { teamId in
                        HStack {
                            Image(systemName: "shield.fill")
                                .foregroundStyle(.green)
                            Text(appState.selectedTeamNames[teamId] ?? "球队 #\(teamId)")
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
            Section("已选赛事 (\(appState.selectedCompetitionIds.count))") {
                if appState.selectedCompetitionIds.isEmpty {
                    Text("未选择赛事")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.selectedCompetitionIds, id: \.self) { compId in
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.orange)
                            Text(appState.selectedCompetitionNames[compId] ?? "赛事 #\(compId)")
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
                            Text("添加球队或赛事")
                            Spacer()
                            Text("还可选 \(appState.remainingSlots) 个")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Selection count
            Section {
                HStack {
                    Text("已选择")
                    Spacer()
                    Text("\(appState.totalSelections) / 10")
                        .fontWeight(.semibold)
                        .foregroundStyle(appState.totalSelections >= 10 ? .red : .green)
                }
            } footer: {
                Text("最多可选择 10 个球队和赛事")
            }

            // Reset
            Section {
                Button(role: .destructive) {
                    appState.resetOnboarding()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("重置所有选择")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("设置")
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
            case .competition: return "赛事"
            case .team: return "球队"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("类型", selection: $mode) {
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
            .navigationTitle("添加关注")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    // MARK: - Competitions List

    private var competitionsList: some View {
        Group {
            if isLoadingCompetitions {
                LoadingView("加载赛事列表...")
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
                                    appState.addCompetition(id: comp.id, name: comp.name)
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
                .searchable(text: $searchText, prompt: "搜索赛事")
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
                Text("先选择一个赛事来浏览球队")
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
                            Text("返回")
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
                    LoadingView("加载球队列表...")
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
                                        appState.addTeam(id: team.id, name: team.shortName ?? team.name)
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
                    .searchable(text: $searchText, prompt: "搜索球队")
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
