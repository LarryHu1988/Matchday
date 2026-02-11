import Foundation

// MARK: - Competition Models

struct CompetitionResponse: Codable {
    let competitions: [Competition]
}

struct Competition: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let code: String?
    let type: String?
    let emblem: String?
    let area: Area?
    let currentSeason: Season?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Competition, rhs: Competition) -> Bool {
        lhs.id == rhs.id
    }
}

struct Area: Codable, Hashable {
    let id: Int
    let name: String
    let code: String?
    let flag: String?
}

struct Season: Codable, Hashable {
    let id: Int
    let startDate: String?
    let endDate: String?
    let currentMatchday: Int?
    let winner: TeamRef?
}
