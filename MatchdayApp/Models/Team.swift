import Foundation

// MARK: - Team Models

struct TeamResponse: Codable {
    let teams: [Team]?
}

struct Team: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let shortName: String?
    let tla: String?
    let crest: String?
    let address: String?
    let website: String?
    let founded: Int?
    let clubColors: String?
    let venue: String?
    let coach: Coach?
    let squad: [Player]?
    let staff: [Staff]?
    let runningCompetitions: [CompetitionRef]?
    let area: Area?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Team, rhs: Team) -> Bool {
        lhs.id == rhs.id
    }
}

struct TeamRef: Codable, Hashable {
    let id: Int?
    let name: String?
    let shortName: String?
    let tla: String?
    let crest: String?
}

struct Coach: Codable, Hashable {
    let id: Int?
    let firstName: String?
    let lastName: String?
    let name: String?
    let dateOfBirth: String?
    let nationality: String?
    let contract: Contract?
}

struct Player: Codable, Identifiable, Hashable {
    let id: Int
    let firstName: String?
    let lastName: String?
    let name: String?
    let position: String?
    let dateOfBirth: String?
    let nationality: String?
    let shirtNumber: Int?
    let marketValue: Int?
    let contract: Contract?

    var displayName: String {
        name ?? "\(firstName ?? "") \(lastName ?? "")"
    }

    var positionLabel: String {
        switch position {
        case "Goalkeeper": return L10n.posGoalkeeper
        case "Defence": return L10n.posDefence
        case "Midfield": return L10n.posMidfield
        case "Offence": return L10n.posForward
        default: return position ?? L10n.posUnknown
        }
    }

    var age: Int? {
        guard let dob = dateOfBirth else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let birthDate = formatter.date(from: dob) else { return nil }
        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }
}

struct Staff: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let dateOfBirth: String?
    let nationality: String?
    let contract: Contract?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Staff, rhs: Staff) -> Bool {
        lhs.id == rhs.id
    }
}

struct Contract: Codable, Hashable {
    let start: String?
    let until: String?
}
