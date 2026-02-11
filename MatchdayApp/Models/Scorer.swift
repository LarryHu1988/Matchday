import Foundation

// MARK: - Scorer Models

struct ScorersResponse: Codable {
    let competition: CompetitionRef?
    let season: Season?
    let scorers: [Scorer]
}

struct Scorer: Codable, Identifiable {
    let player: ScorerPlayer
    let team: TeamRef?
    let playedMatches: Int?
    let goals: Int?
    let assists: Int?
    let penalties: Int?

    var id: Int { player.id }
}

struct ScorerPlayer: Codable {
    let id: Int
    let name: String
    let firstName: String?
    let lastName: String?
    let dateOfBirth: String?
    let nationality: String?
    let position: String?
    let shirtNumber: Int?
}
