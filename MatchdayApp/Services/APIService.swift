import Foundation

// MARK: - Football-Data.org API Client

actor APIService {
    static let shared = APIService()

    private let baseURL = "https://api.football-data.org/v4"
    // Register at https://www.football-data.org/ to get your free API key
    private var apiKey: String {
        UserDefaults.standard.string(forKey: "api_key") ?? "YOUR_API_KEY"
    }

    private let session: URLSession
    private let decoder: JSONDecoder

    // Simple rate limiting: track last request time
    private var lastRequestTime: Date?
    private let minInterval: TimeInterval = 6.5 // ~10 req/min for free tier

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    // MARK: - Core Request

    private func request<T: Decodable>(_ endpoint: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        // Rate limiting
        if let last = lastRequestTime {
            let elapsed = Date().timeIntervalSince(last)
            if elapsed < minInterval {
                try await Task.sleep(nanoseconds: UInt64((minInterval - elapsed) * 1_000_000_000))
            }
        }

        var components = URLComponents(string: "\(baseURL)\(endpoint)")!
        components.queryItems = queryItems

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        lastRequestTime = Date()

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try decoder.decode(T.self, from: data)
        case 429:
            throw APIError.rateLimited
        case 403:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(httpResponse.statusCode)
        }
    }

    // MARK: - Competitions

    func fetchCompetitions() async throws -> [Competition] {
        let response: CompetitionResponse = try await request("/competitions")
        return response.competitions
    }

    func fetchCompetition(id: Int) async throws -> Competition {
        return try await request("/competitions/\(id)")
    }

    // MARK: - Standings

    func fetchStandings(competitionId: Int) async throws -> StandingsResponse {
        return try await request("/competitions/\(competitionId)/standings")
    }

    func fetchStandings(competitionCode: String) async throws -> StandingsResponse {
        return try await request("/competitions/\(competitionCode)/standings")
    }

    // MARK: - Scorers

    func fetchScorers(competitionId: Int, limit: Int = 20) async throws -> ScorersResponse {
        return try await request("/competitions/\(competitionId)/scorers",
                                queryItems: [URLQueryItem(name: "limit", value: "\(limit)")])
    }

    func fetchScorers(competitionCode: String, limit: Int = 20) async throws -> ScorersResponse {
        return try await request("/competitions/\(competitionCode)/scorers",
                                queryItems: [URLQueryItem(name: "limit", value: "\(limit)")])
    }

    // MARK: - Matches

    func fetchCompetitionMatches(competitionId: Int, dateFrom: String? = nil, dateTo: String? = nil, status: String? = nil, matchday: Int? = nil) async throws -> MatchResponse {
        var items: [URLQueryItem] = []
        if let dateFrom { items.append(URLQueryItem(name: "dateFrom", value: dateFrom)) }
        if let dateTo { items.append(URLQueryItem(name: "dateTo", value: dateTo)) }
        if let status { items.append(URLQueryItem(name: "status", value: status)) }
        if let matchday { items.append(URLQueryItem(name: "matchday", value: "\(matchday)")) }
        return try await request("/competitions/\(competitionId)/matches", queryItems: items.isEmpty ? nil : items)
    }

    func fetchTeamMatches(teamId: Int, dateFrom: String? = nil, dateTo: String? = nil, status: String? = nil, limit: Int = 50) async throws -> MatchResponse {
        var items: [URLQueryItem] = [URLQueryItem(name: "limit", value: "\(limit)")]
        if let dateFrom { items.append(URLQueryItem(name: "dateFrom", value: dateFrom)) }
        if let dateTo { items.append(URLQueryItem(name: "dateTo", value: dateTo)) }
        if let status { items.append(URLQueryItem(name: "status", value: status)) }
        return try await request("/teams/\(teamId)/matches", queryItems: items)
    }

    func fetchTodayMatches() async throws -> MatchResponse {
        return try await request("/matches")
    }

    // MARK: - Teams

    func fetchTeam(id: Int) async throws -> Team {
        return try await request("/teams/\(id)")
    }

    func fetchCompetitionTeams(competitionId: Int) async throws -> TeamResponse {
        return try await request("/competitions/\(competitionId)/teams")
    }

    // MARK: - Persons

    func fetchPerson(id: Int) async throws -> Player {
        return try await request("/persons/\(id)")
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidResponse
    case rateLimited
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return L10n.errorInvalidResponse
        case .rateLimited: return L10n.errorRateLimited
        case .unauthorized: return L10n.errorUnauthorized
        case .notFound: return L10n.errorNotFound
        case .serverError(let code): return L10n.errorServer(code)
        case .decodingError(let error): return L10n.errorDecoding(error.localizedDescription)
        }
    }
}
