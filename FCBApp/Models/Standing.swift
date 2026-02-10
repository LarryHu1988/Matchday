import Foundation

// MARK: - Standing Models

struct StandingsResponse: Codable {
    let competition: CompetitionRef?
    let season: Season?
    let standings: [StandingGroup]
}

struct StandingGroup: Codable, Identifiable {
    let stage: String?
    let type: String?
    let group: String?
    let table: [StandingRow]

    var id: String {
        "\(stage ?? "")-\(type ?? "")-\(group ?? "")"
    }

    var groupName: String {
        if let group = group {
            return group.replacingOccurrences(of: "GROUP_", with: "小组 ")
        }
        switch type {
        case "TOTAL": return "总榜"
        case "HOME": return "主场"
        case "AWAY": return "客场"
        default: return type ?? ""
        }
    }
}

struct StandingRow: Codable, Identifiable {
    let position: Int
    let team: TeamRef
    let playedGames: Int
    let form: String?
    let won: Int
    let draw: Int
    let lost: Int
    let points: Int
    let goalsFor: Int
    let goalsAgainst: Int
    let goalDifference: Int

    var id: Int { position }
}
