import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var localization: LocalizationManager
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

            Text("Matchday")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(L10n.onboardingSlogan)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text("Your matches. Your matchday.")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.7))
                .italic()

            Text(L10n.onboardingDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                currentStep = .apiKey
            } label: {
                Text(L10n.startSetup)
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

            Text(L10n.configureApiKey)
                .font(.title2)
                .fontWeight(.bold)

            Text(L10n.apiKeyDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField(L10n.enterYourApiKey, text: $apiKeyInput)
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
                    Text(apiKeyInput.isEmpty ? L10n.configureLater : L10n.next)
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
                    Text(L10n.back)
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
                Text(L10n.selectCompetitions)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(L10n.selectedCount(appState.totalSelections))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            if isLoading {
                LoadingView(L10n.loadingCompShort)
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
                                    appState.addCompetition(id: comp.id, name: comp.name, emblem: comp.emblem)
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
                    Text(L10n.selectTeams)
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
                        Text(L10n.finishSetup(appState.totalSelections))
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
                Text(L10n.selectTeams)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(L10n.selectedCount(appState.totalSelections))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            if selectedCompForTeams == nil {
                // Pick a competition first
                Text(L10n.selectCompToBrowseTeams)
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
                            Text(L10n.backToCompetitions)
                        }
                        .font(.subheadline)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                if isLoading {
                    LoadingView(L10n.loadingTeamsShort)
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
                                        appState.addTeam(id: team.id, name: team.shortName ?? team.name, crest: team.crest)
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
                        Text(L10n.finishSetup(appState.totalSelections))
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
                    Text(L10n.backToSelectComp)
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
