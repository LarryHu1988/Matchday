import Foundation

// MARK: - Match Models

struct MatchResponse: Codable {
    let matches: [Match]
    let resultSet: ResultSet?
}

struct ResultSet: Codable {
    let count: Int?
    let competitions: String?
    let first: String?
    let last: String?
}

struct Match: Codable, Identifiable {
    let id: Int
    let utcDate: String
    let status: String
    let matchday: Int?
    let stage: String?
    let group: String?
    let venue: String?
    let homeTeam: TeamRef
    let awayTeam: TeamRef
    let score: Score?
    let competition: CompetitionRef?
    let area: Area?

    var date: Date? {
        ISO8601DateFormatter().date(from: utcDate)
    }

    var isFinished: Bool {
        status == "FINISHED"
    }

    var isLive: Bool {
        status == "IN_PLAY" || status == "PAUSED" || status == "EXTRA_TIME" || status == "PENALTY_SHOOTOUT"
    }

    var isScheduled: Bool {
        status == "SCHEDULED" || status == "TIMED"
    }

    var statusText: String {
        switch status {
        case "FINISHED": return L10n.matchFinished
        case "IN_PLAY": return L10n.matchInPlay
        case "PAUSED": return L10n.matchPaused
        case "EXTRA_TIME": return L10n.matchExtraTime
        case "PENALTY_SHOOTOUT": return L10n.matchPenaltyShootout
        case "SCHEDULED", "TIMED": return L10n.matchScheduled
        case "POSTPONED": return L10n.matchPostponed
        case "CANCELLED": return L10n.matchCancelled
        case "SUSPENDED": return L10n.matchSuspended
        default: return status
        }
    }

    var scoreText: String {
        guard let score = score else { return "vs" }
        if isFinished || isLive {
            let home = score.fullTime?.home ?? 0
            let away = score.fullTime?.away ?? 0
            return "\(home) - \(away)"
        }
        return "vs"
    }

    var timeText: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }

    var dateText: String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: L10n.dateLocaleId)
        formatter.dateFormat = L10n.dateFormat
        return formatter.string(from: date)
    }
}

struct CompetitionRef: Codable {
    let id: Int
    let name: String
    let code: String?
    let type: String?
    let emblem: String?
}

struct Score: Codable {
    let winner: String?
    let duration: String?
    let fullTime: ScoreDetail?
    let halfTime: ScoreDetail?
}

struct ScoreDetail: Codable {
    let home: Int?
    let away: Int?
}
