import SwiftUI

// MARK: - App State (Source of Truth)

@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedTeamIds: [Int] = [] {
        didSet { saveSelections() }
    }
    @Published var selectedCompetitionIds: [Int] = [] {
        didSet { saveSelections() }
    }
    @Published var hasCompletedOnboarding: Bool = false {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }
    @Published var apiKey: String = "" {
        didSet { UserDefaults.standard.set(apiKey, forKey: "api_key") }
    }

    // MARK: - Cached Data
    @Published var competitions: [Competition] = []
    @Published var selectedTeams: [Team] = []

    // MARK: - Selection Info (for display)
    @Published var selectedTeamNames: [Int: String] = [:]
    @Published var selectedCompetitionNames: [Int: String] = [:]
    @Published var selectedTeamCrests: [Int: String] = [:]
    @Published var selectedCompetitionEmblems: [Int: String] = [:]

    var totalSelections: Int {
        selectedTeamIds.count + selectedCompetitionIds.count
    }

    var canAddMore: Bool {
        totalSelections < 10
    }

    var remainingSlots: Int {
        max(0, 10 - totalSelections)
    }

    // MARK: - Init

    init() {
        loadSelections()
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.apiKey = UserDefaults.standard.string(forKey: "api_key") ?? ""
    }

    // MARK: - Persistence

    private func saveSelections() {
        UserDefaults.standard.set(selectedTeamIds, forKey: "selectedTeamIds")
        UserDefaults.standard.set(selectedCompetitionIds, forKey: "selectedCompetitionIds")

        // Save names and image URLs
        if let data = try? JSONEncoder().encode(selectedTeamNames) {
            UserDefaults.standard.set(data, forKey: "selectedTeamNames")
        }
        if let data = try? JSONEncoder().encode(selectedCompetitionNames) {
            UserDefaults.standard.set(data, forKey: "selectedCompetitionNames")
        }
        if let data = try? JSONEncoder().encode(selectedTeamCrests) {
            UserDefaults.standard.set(data, forKey: "selectedTeamCrests")
        }
        if let data = try? JSONEncoder().encode(selectedCompetitionEmblems) {
            UserDefaults.standard.set(data, forKey: "selectedCompetitionEmblems")
        }
    }

    private func loadSelections() {
        selectedTeamIds = UserDefaults.standard.array(forKey: "selectedTeamIds") as? [Int] ?? []
        selectedCompetitionIds = UserDefaults.standard.array(forKey: "selectedCompetitionIds") as? [Int] ?? []

        if let data = UserDefaults.standard.data(forKey: "selectedTeamNames"),
           let names = try? JSONDecoder().decode([Int: String].self, from: data) {
            selectedTeamNames = names
        }
        if let data = UserDefaults.standard.data(forKey: "selectedCompetitionNames"),
           let names = try? JSONDecoder().decode([Int: String].self, from: data) {
            selectedCompetitionNames = names
        }
        if let data = UserDefaults.standard.data(forKey: "selectedTeamCrests"),
           let urls = try? JSONDecoder().decode([Int: String].self, from: data) {
            selectedTeamCrests = urls
        }
        if let data = UserDefaults.standard.data(forKey: "selectedCompetitionEmblems"),
           let urls = try? JSONDecoder().decode([Int: String].self, from: data) {
            selectedCompetitionEmblems = urls
        }
    }

    // MARK: - Selection Management

    func addTeam(id: Int, name: String, crest: String? = nil) {
        guard canAddMore, !selectedTeamIds.contains(id) else { return }
        selectedTeamIds.append(id)
        selectedTeamNames[id] = name
        if let crest { selectedTeamCrests[id] = crest }
    }

    func removeTeam(id: Int) {
        selectedTeamIds.removeAll { $0 == id }
        selectedTeamNames.removeValue(forKey: id)
        selectedTeamCrests.removeValue(forKey: id)
    }

    func addCompetition(id: Int, name: String, emblem: String? = nil) {
        guard canAddMore, !selectedCompetitionIds.contains(id) else { return }
        selectedCompetitionIds.append(id)
        selectedCompetitionNames[id] = name
        if let emblem { selectedCompetitionEmblems[id] = emblem }
    }

    func removeCompetition(id: Int) {
        selectedCompetitionIds.removeAll { $0 == id }
        selectedCompetitionNames.removeValue(forKey: id)
        selectedCompetitionEmblems.removeValue(forKey: id)
    }

    func isTeamSelected(_ id: Int) -> Bool {
        selectedTeamIds.contains(id)
    }

    func isCompetitionSelected(_ id: Int) -> Bool {
        selectedCompetitionIds.contains(id)
    }

    // MARK: - Data Loading

    func loadCompetitions() async {
        do {
            competitions = try await APIService.shared.fetchCompetitions()
        } catch {
            print("Failed to load competitions: \(error)")
        }
    }

    func loadSelectedTeams() async {
        var teams: [Team] = []
        for teamId in selectedTeamIds {
            do {
                let team = try await APIService.shared.fetchTeam(id: teamId)
                teams.append(team)
            } catch {
                print("Failed to load team \(teamId): \(error)")
            }
        }
        selectedTeams = teams
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        selectedTeamIds = []
        selectedCompetitionIds = []
        selectedTeamNames = [:]
        selectedCompetitionNames = [:]
        selectedTeamCrests = [:]
        selectedCompetitionEmblems = [:]
        selectedTeams = []
        hasCompletedOnboarding = false
    }
}
