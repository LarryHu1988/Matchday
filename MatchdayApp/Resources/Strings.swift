import Foundation

// MARK: - Localized Strings

enum L10n {
    private static var isCN: Bool { AppLanguage.current == .chinese }

    // MARK: - Common
    static var loading: String { isCN ? "加载中..." : "Loading..." }
    static var retry: String { isCN ? "重试" : "Retry" }
    static var back: String { isCN ? "返回" : "Back" }
    static var done: String { isCN ? "完成" : "Done" }
    static var save: String { isCN ? "保存" : "Save" }
    static var options: String { isCN ? "选项" : "Options" }
    static var type: String { isCN ? "类型" : "Type" }
    static var filter: String { isCN ? "筛选" : "Filter" }
    static var noData: String { isCN ? "暂无数据" : "No Data" }
    static var other: String { isCN ? "其他" : "Other" }
    static var selected: String { isCN ? "已选择" : "Selected" }

    // MARK: - Tabs
    static var tabKickoff: String { isCN ? "赛程" : "Kickoff" }
    static var tabStats: String { isCN ? "赛事" : "Stats" }
    static var tabTeams: String { isCN ? "球队" : "Teams" }

    // MARK: - Navigation Titles
    static var schedule: String { isCN ? "赛程" : "Schedule" }
    static var competitions: String { isCN ? "赛事" : "Competitions" }
    static var teams: String { isCN ? "球队" : "Teams" }
    static var team: String { isCN ? "球队" : "Team" }
    static var settings: String { isCN ? "设置" : "Settings" }

    // MARK: - Schedule
    static var scheduleUpcoming: String { isCN ? "未来赛程" : "Upcoming" }
    static var scheduleResults: String { isCN ? "已完赛" : "Results" }
    static var scheduleAll: String { isCN ? "全部" : "All" }
    static var loadingSchedule: String { isCN ? "加载赛程中..." : "Loading schedule..." }
    static var noSchedule: String { isCN ? "暂无赛程" : "No Matches" }
    static var noScheduleMessage: String { isCN ? "所选球队或赛事暂无比赛安排" : "No matches scheduled for your selections" }
    static func matchdayRound(_ n: Int) -> String { isCN ? "第\(n)轮" : "Matchday \(n)" }
    static var homeTeam: String { isCN ? "主队" : "Home" }
    static var awayTeam: String { isCN ? "客队" : "Away" }

    // MARK: - Match Status
    static var matchFinished: String { isCN ? "完场" : "FT" }
    static var matchInPlay: String { isCN ? "进行中" : "LIVE" }
    static var matchPaused: String { isCN ? "中场" : "HT" }
    static var matchExtraTime: String { isCN ? "加时" : "ET" }
    static var matchPenaltyShootout: String { isCN ? "点球" : "PEN" }
    static var matchScheduled: String { isCN ? "未开始" : "Upcoming" }
    static var matchPostponed: String { isCN ? "延期" : "PPD" }
    static var matchCancelled: String { isCN ? "取消" : "CANC" }
    static var matchSuspended: String { isCN ? "暂停" : "SUSP" }

    // MARK: - Date Format
    static var dateLocaleId: String { isCN ? "zh_CN" : "en_US" }
    static var dateFormat: String { isCN ? "MM月dd日 EEEE" : "EEE, MMM d" }

    // MARK: - Positions
    static var posGoalkeeper: String { isCN ? "门将" : "GK" }
    static var posDefence: String { isCN ? "后卫" : "DEF" }
    static var posMidfield: String { isCN ? "中场" : "MID" }
    static var posForward: String { isCN ? "前锋" : "FWD" }
    static var posUnknown: String { isCN ? "未知" : "N/A" }

    // MARK: - Standings
    static var standings: String { isCN ? "积分榜" : "Standings" }
    static var standingTotal: String { isCN ? "总榜" : "Overall" }
    static var standingHome: String { isCN ? "主场" : "Home" }
    static var standingAway: String { isCN ? "客场" : "Away" }
    static var standingGroupPrefix: String { isCN ? "小组 " : "Group " }
    static var loadingStandings: String { isCN ? "加载积分榜..." : "Loading standings..." }
    static var noStandingsData: String { isCN ? "该赛事暂无积分榜数据" : "No standings data available" }
    // Table headers
    static var played: String { isCN ? "赛" : "P" }
    static var won: String { isCN ? "胜" : "W" }
    static var draw: String { isCN ? "平" : "D" }
    static var lost: String { isCN ? "负" : "L" }
    static var goalDiff: String { isCN ? "净胜" : "GD" }
    static var points: String { isCN ? "积分" : "Pts" }

    // MARK: - Scorers
    static var topScorers: String { isCN ? "射手榜" : "Top Scorers" }
    static var topAssists: String { isCN ? "助攻榜" : "Top Assists" }
    static var loadingScorers: String { isCN ? "加载射手榜..." : "Loading scorers..." }
    static var loadingAssists: String { isCN ? "加载助攻榜..." : "Loading assists..." }
    static var noScorersData: String { isCN ? "该赛事暂无射手数据" : "No scorer data available" }
    static var noAssistsData: String { isCN ? "该赛事暂无助攻数据" : "No assist data available" }
    static var player: String { isCN ? "球员" : "Player" }
    static var matchesPlayed: String { isCN ? "场次" : "Apps" }
    static var goals: String { isCN ? "进球" : "Goals" }
    static var assists: String { isCN ? "助攻" : "Assists" }

    // MARK: - Competitions View
    static var noCompetitionsSelected: String { isCN ? "未选择赛事" : "No Competitions" }
    static var noCompetitionsMessage: String { isCN ? "请在球队页面的设置中添加要关注的赛事" : "Add competitions in Settings" }

    // MARK: - Teams View
    static var noTeamsSelected: String { isCN ? "未选择球队" : "No Teams" }
    static var noTeamsMessage: String { isCN ? "请在设置中添加要关注的球队" : "Add teams in Settings" }
    static var overview: String { isCN ? "概览" : "Overview" }
    static var squad: String { isCN ? "阵容" : "Squad" }
    static var loadingTeam: String { isCN ? "加载球队信息..." : "Loading team..." }
    static var loadingMatches: String { isCN ? "加载赛程..." : "Loading matches..." }
    static var noMatchesScheduled: String { isCN ? "暂无赛程安排" : "No matches scheduled" }
    static func ageYears(_ age: Int) -> String { isCN ? "\(age)岁" : "\(age)y" }
    // Team detail labels
    static var basicInfo: String { isCN ? "基本信息" : "Basic Info" }
    static var founded: String { isCN ? "成立年份" : "Founded" }
    static var clubColors: String { isCN ? "队色" : "Colors" }
    static var address: String { isCN ? "地址" : "Address" }
    static var website: String { isCN ? "官网" : "Website" }
    static var headCoach: String { isCN ? "主教练" : "Head Coach" }
    static var nationality: String { isCN ? "国籍" : "Nationality" }
    static var dateOfBirth: String { isCN ? "出生日期" : "Date of Birth" }
    static var contractUntil: String { isCN ? "合同到期" : "Contract Until" }
    static var runningCompetitions: String { isCN ? "参加赛事" : "Competitions" }

    // MARK: - Settings
    static var language: String { isCN ? "语言" : "Language" }
    static var apiConfig: String { isCN ? "API 配置" : "API Configuration" }
    static var enterApiKey: String { isCN ? "输入Football-Data.org API Key" : "Enter Football-Data.org API Key" }
    static var apiKeyHint: String { isCN ? "在 football-data.org 免费注册获取" : "Register free at football-data.org" }
    static func selectedTeamsSection(_ count: Int) -> String { isCN ? "已选球队 (\(count))" : "Selected Teams (\(count))" }
    static func selectedCompetitionsSection(_ count: Int) -> String { isCN ? "已选赛事 (\(count))" : "Selected Competitions (\(count))" }
    static func teamFallback(_ id: Int) -> String { isCN ? "球队 #\(id)" : "Team #\(id)" }
    static func competitionFallback(_ id: Int) -> String { isCN ? "赛事 #\(id)" : "Competition #\(id)" }
    static var addTeamOrCompetition: String { isCN ? "添加球队或赛事" : "Add Team or Competition" }
    static func remainingSlots(_ n: Int) -> String { isCN ? "还可选 \(n) 个" : "\(n) slots left" }
    static var maxSelections: String { isCN ? "最多可选择 10 个球队和赛事" : "Up to 10 teams and competitions" }
    static var resetAll: String { isCN ? "重置所有选择" : "Reset All" }
    static var addFollowing: String { isCN ? "添加关注" : "Add to Follow" }
    static var loadingCompetitions: String { isCN ? "加载赛事列表..." : "Loading competitions..." }
    static var searchCompetitions: String { isCN ? "搜索赛事" : "Search competitions" }
    static var selectCompetitionFirst: String { isCN ? "先选择一个赛事来浏览球队" : "Select a competition to browse teams" }
    static var loadingTeams: String { isCN ? "加载球队列表..." : "Loading teams..." }
    static var searchTeams: String { isCN ? "搜索球队" : "Search teams" }
    static var noTeamsSelectedShort: String { isCN ? "未选择球队" : "No teams selected" }
    static var noCompetitionsSelectedShort: String { isCN ? "未选择赛事" : "No competitions selected" }
    static var competitionMode: String { isCN ? "赛事" : "Competitions" }
    static var teamMode: String { isCN ? "球队" : "Teams" }

    // MARK: - Onboarding
    static var onboardingSlogan: String { isCN ? "只看你的比赛日" : "Your matches. Your matchday." }
    static var onboardingDescription: String { isCN ? "选择你关注的球队和赛事\n最多 10 个" : "Choose your teams and competitions\nUp to 10" }
    static var startSetup: String { isCN ? "开始设置" : "Get Started" }
    static var configureApiKey: String { isCN ? "配置 API Key" : "Configure API Key" }
    static var apiKeyDescription: String { isCN ? "请在 football-data.org 注册\n获取免费 API Key" : "Register at football-data.org\nto get a free API Key" }
    static var enterYourApiKey: String { isCN ? "输入你的 API Key" : "Enter your API Key" }
    static var configureLater: String { isCN ? "稍后配置" : "Later" }
    static var next: String { isCN ? "下一步" : "Next" }
    static var selectCompetitions: String { isCN ? "选择赛事" : "Select Competitions" }
    static func selectedCount(_ n: Int) -> String { isCN ? "已选 \(n)/10" : "\(n)/10 selected" }
    static var selectTeams: String { isCN ? "选择球队" : "Select Teams" }
    static func finishSetup(_ n: Int) -> String { isCN ? "完成设置 (\(n) 个已选)" : "Finish (\(n) selected)" }
    static var selectCompToBrowseTeams: String { isCN ? "选择一个赛事来浏览球队" : "Select a competition to browse teams" }
    static var backToCompetitions: String { isCN ? "返回赛事列表" : "Back" }
    static var backToSelectComp: String { isCN ? "返回选赛事" : "Back" }
    static var loadingCompShort: String { isCN ? "加载赛事..." : "Loading..." }
    static var loadingTeamsShort: String { isCN ? "加载球队..." : "Loading..." }

    // MARK: - Segment Tabs (Redesigned UI)
    static var segSchedule: String { isCN ? "赛程" : "Schedule" }
    static var segStandings: String { isCN ? "积分" : "Standings" }
    static var segPlayers: String { isCN ? "球员" : "Players" }
    static var segTeamsTab: String { isCN ? "球队" : "Teams" }
    static var segSquad: String { isCN ? "阵容" : "Squad" }
    static var segStats: String { isCN ? "数据" : "Stats" }
    static var segInfo: String { isCN ? "资料" : "Info" }
    static var allTeams: String { isCN ? "全部" : "All" }
    static var allCompetitions: String { isCN ? "全部" : "All" }

    // MARK: - API Errors
    static var errorInvalidResponse: String { isCN ? "无效的服务器响应" : "Invalid server response" }
    static var errorRateLimited: String { isCN ? "请求过于频繁，请稍后再试" : "Too many requests, try again later" }
    static var errorUnauthorized: String { isCN ? "API密钥无效，请在设置中配置" : "Invalid API key, configure in Settings" }
    static var errorNotFound: String { isCN ? "未找到请求的资源" : "Resource not found" }
    static func errorServer(_ code: Int) -> String { isCN ? "服务器错误 (\(code))" : "Server error (\(code))" }
    static func errorDecoding(_ detail: String) -> String { isCN ? "数据解析错误: \(detail)" : "Data error: \(detail)" }
}
