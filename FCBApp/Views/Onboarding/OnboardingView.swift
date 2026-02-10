import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep: OnboardingStep = .welcome
    @State private var apiKeyInput = ""
    @State private var competitions: [Competition] = []
    @State private var teams: [Team] = []
    @State private var isLoading = false
    @State private var selectedCompForTeams: Competition?

    enum OnboardingStep {
        case welcome
        case apiKey
        case selectCompetitions
        case selectTeams
    }

    var body: some View {
        NavigationStack {
            VStack {
                switch currentStep {
                case .welcome:
                    welcomeStep
                case .apiKey:
                    apiKeyStep
                case .selectCompetitions:
                    selectCompetitionsStep
                case .selectTeams:
                    selectTeamsStep
                }
            }
            .animation(.easeInOut, value: currentStep)
        }
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "soccerball")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("FCB")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("极简足球资讯")
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("选择你关注的球队和赛事\n最多 10 个")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                currentStep = .apiKey
            } label: {
                Text("开始设置")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - API Key

    private var apiKeyStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("配置 API Key")
                .font(.title2)
                .fontWeight(.bold)

            Text("请在 football-data.org 注册\n获取免费 API Key")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("输入你的 API Key", text: $apiKeyInput)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    if !apiKeyInput.isEmpty {
                        appState.apiKey = apiKeyInput
                    }
                    currentStep = .selectCompetitions
                } label: {
                    Text(apiKeyInput.isEmpty ? "稍后配置" : "下一步")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(apiKeyInput.isEmpty ? .gray : .green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    currentStep = .welcome
                } label: {
                    Text("返回")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Select Competitions

    private var selectCompetitionsStep: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("选择赛事")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("已选 \(appState.totalSelections)/10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            if isLoading {
                LoadingView("加载赛事...")
            } else {
                List {
                    ForEach(competitions) { comp in
                        HStack {
                            CrestImage(comp.emblem, size: 28)
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
                                Button {
                                    appState.removeCompetition(id: comp.id)
                                } label: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.title3)
                                }
                            } else if appState.canAddMore {
                                Button {
                                    appState.addCompetition(id: comp.id, name: comp.name)
                                } label: {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.gray)
                                        .font(.title3)
                                }
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.gray.opacity(0.3))
                                    .font(.title3)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }

            // Bottom buttons
            VStack(spacing: 12) {
                Button {
                    currentStep = .selectTeams
                } label: {
                    Text("选择球队")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if appState.totalSelections > 0 {
                    Button {
                        appState.completeOnboarding()
                    } label: {
                        Text("完成设置 (\(appState.totalSelections) 个已选)")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
        .task {
            if competitions.isEmpty {
                await loadCompetitions()
            }
        }
    }

    // MARK: - Select Teams

    private var selectTeamsStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("选择球队")
                    .font(.title3)
                    .fontWeight(.bold)
                Text("已选 \(appState.totalSelections)/10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            if selectedCompForTeams == nil {
                // Pick a competition first
                Text("选择一个赛事来浏览球队")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)

                List {
                    ForEach(competitions) { comp in
                        Button {
                            selectedCompForTeams = comp
                            Task { await loadTeams(competitionId: comp.id) }
                        } label: {
                            HStack {
                                CrestImage(comp.emblem, size: 24)
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
            } else {
                // Show teams
                HStack {
                    Button {
                        selectedCompForTeams = nil
                        teams = []
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("返回赛事列表")
                        }
                        .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                if isLoading {
                    LoadingView("加载球队...")
                } else {
                    List {
                        ForEach(teams) { team in
                            HStack {
                                CrestImage(team.crest, size: 28)
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
                                    Button {
                                        appState.removeTeam(id: team.id)
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.title3)
                                    }
                                } else if appState.canAddMore {
                                    Button {
                                        appState.addTeam(id: team.id, name: team.shortName ?? team.name)
                                    } label: {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.gray)
                                            .font(.title3)
                                    }
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.gray.opacity(0.3))
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }

            // Bottom buttons
            VStack(spacing: 12) {
                if appState.totalSelections > 0 {
                    Button {
                        appState.completeOnboarding()
                    } label: {
                        Text("完成设置 (\(appState.totalSelections) 个已选)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

                Button {
                    currentStep = .selectCompetitions
                } label: {
                    Text("返回选赛事")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
        .task {
            if competitions.isEmpty {
                await loadCompetitions()
            }
        }
    }

    // MARK: - Data Loading

    private func loadCompetitions() async {
        isLoading = true
        do {
            let allComps = try await APIService.shared.fetchCompetitions()
            let freeCodes = Set(["PL", "BL1", "PD", "SA", "FL1", "ELC", "DED", "PPL", "BSA", "CL", "WC", "EC"])
            competitions = allComps.filter { freeCodes.contains($0.code ?? "") }
        } catch {
            print("Failed to load competitions: \(error)")
        }
        isLoading = false
    }

    private func loadTeams(competitionId: Int) async {
        isLoading = true
        do {
            let response = try await APIService.shared.fetchCompetitionTeams(competitionId: competitionId)
            teams = response.teams ?? []
        } catch {
            print("Failed to load teams: \(error)")
        }
        isLoading = false
    }
}
