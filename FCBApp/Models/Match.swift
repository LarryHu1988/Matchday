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
        case "FINISHED": return "完场"
        case "IN_PLAY": return "进行中"
        case "PAUSED": return "中场"
        case "EXTRA_TIME": return "加时"
        case "PENALTY_SHOOTOUT": return "点球"
        case "SCHEDULED", "TIMED": return "未开始"
        case "POSTPONED": return "延期"
        case "CANCELLED": return "取消"
        case "SUSPENDED": return "暂停"
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
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日 EEEE"
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
