import Foundation

/**
 UsageMetrics - User Activity Tracking

 LEARNING: Analytics & Metrics
 ==============================
 Track user behavior to:
 - Show usage statistics
 - Identify power users
 - Measure engagement
 - Optimize features
 - Predict churn

 PRIVACY:
 - No personal data
 - Aggregate only
 - User can opt-out
 - GDPR compliant
 */

struct UsageMetrics: Codable, Equatable {

    // MARK: - Properties

    /// User identifier (for attribution)
    let userId: String

    /// Total replies generated (all time)
    var totalRepliesGenerated: Int

    /// Replies generated today
    var repliesToday: Int

    /// Replies generated this week
    var repliesThisWeek: Int

    /// Replies generated this month
    var repliesThisMonth: Int

    /// Most used tone
    var toneUsage: [Tone: Int]

    /// Most used platform
    var platformUsage: [Platform: Int]

    /// Average response time (seconds)
    var averageResponseTime: Double

    /// Number of times suggestions were copied
    var copiedCount: Int

    /// Number of times suggestions were edited before use
    var editedCount: Int

    /// User satisfaction ratings (1-5 stars)
    var satisfactionRatings: [Int]

    /// Last activity timestamp
    var lastActivityDate: Date

    /// Account creation date
    let accountCreatedDate: Date

    /// Current streak (consecutive days of usage)
    var currentStreak: Int

    /// Longest streak
    var longestStreak: Int

    /// Last streak update date
    var lastStreakDate: Date

    // MARK: - Initialization

    init(userId: String) {
        self.userId = userId
        self.totalRepliesGenerated = 0
        self.repliesToday = 0
        self.repliesThisWeek = 0
        self.repliesThisMonth = 0
        self.toneUsage = [:]
        self.platformUsage = [:]
        self.averageResponseTime = 0.0
        self.copiedCount = 0
        self.editedCount = 0
        self.satisfactionRatings = []
        self.lastActivityDate = Date()
        self.accountCreatedDate = Date()
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastStreakDate = Date()
    }

    // MARK: - Computed Properties

    /**
     LEARNING: Computed Properties for Analytics
     ===========================================
     Calculate insights on-the-fly
     No need to store derived values
     Always up-to-date
     */

    /// Average satisfaction rating (1-5)
    var averageSatisfaction: Double {
        guard !satisfactionRatings.isEmpty else { return 0.0 }
        let sum = satisfactionRatings.reduce(0, +)
        return Double(sum) / Double(satisfactionRatings.count)
    }

    /// Most frequently used tone
    var mostUsedTone: Tone? {
        toneUsage.max(by: { $0.value < $1.value })?.key
    }

    /// Most frequently used platform
    var mostUsedPlatform: Platform? {
        platformUsage.max(by: { $0.value < $1.value })?.key
    }

    /// Percentage of replies that were copied
    var copyRate: Double {
        guard totalRepliesGenerated > 0 else { return 0.0 }
        return Double(copiedCount) / Double(totalRepliesGenerated)
    }

    /// Percentage of replies that were edited
    var editRate: Double {
        guard totalRepliesGenerated > 0 else { return 0.0 }
        return Double(editedCount) / Double(totalRepliesGenerated)
    }

    /// Days since account creation
    var accountAgeDays: Int {
        Calendar.current.dateComponents([.day], from: accountCreatedDate, to: Date()).day ?? 0
    }

    /// Days since last activity
    var daysSinceLastActivity: Int {
        Calendar.current.dateComponents([.day], from: lastActivityDate, to: Date()).day ?? 0
    }

    /// Whether user is active (used in last 7 days)
    var isActiveUser: Bool {
        daysSinceLastActivity <= 7
    }

    /// Whether user is at risk of churning (inactive 14+ days)
    var isChurnRisk: Bool {
        daysSinceLastActivity >= 14
    }

    /// User engagement level
    var engagementLevel: EngagementLevel {
        let repliesPerDay = Double(totalRepliesGenerated) / max(1.0, Double(accountAgeDays))

        switch repliesPerDay {
        case 10...:
            return .powerUser
        case 5..<10:
            return .active
        case 1..<5:
            return .casual
        default:
            return .inactive
        }
    }

    /// Tone diversity (how many different tones used)
    var toneDiversity: Int {
        toneUsage.filter { $0.value > 0 }.count
    }

    /// Platform diversity (how many different platforms used)
    var platformDiversity: Int {
        platformUsage.filter { $0.value > 0 }.count
    }

    // MARK: - Methods

    /**
     LEARNING: Tracking Methods
     ==========================
     Update metrics when user performs actions
     All mutating because structs are immutable
     */

    /// Record a new reply generation
    mutating func recordReply(tone: Tone, platform: Platform, responseTime: Double) {
        // Increment counters
        totalRepliesGenerated += 1
        repliesToday += 1
        repliesThisWeek += 1
        repliesThisMonth += 1

        // Update tone usage
        toneUsage[tone, default: 0] += 1

        // Update platform usage
        platformUsage[platform, default: 0] += 1

        // Update average response time (rolling average)
        averageResponseTime = (averageResponseTime * Double(totalRepliesGenerated - 1) + responseTime) / Double(totalRepliesGenerated)

        // Update activity
        updateActivity()
    }

    /// Record that user copied a suggestion
    mutating func recordCopy() {
        copiedCount += 1
        updateActivity()
    }

    /// Record that user edited a suggestion
    mutating func recordEdit() {
        editedCount += 1
        updateActivity()
    }

    /// Record satisfaction rating (1-5 stars)
    mutating func recordSatisfaction(rating: Int) {
        guard (1...5).contains(rating) else { return }
        satisfactionRatings.append(rating)

        // Keep only last 100 ratings for performance
        if satisfactionRatings.count > 100 {
            satisfactionRatings.removeFirst()
        }

        updateActivity()
    }

    /// Update last activity and streak
    private mutating func updateActivity() {
        let now = Date()
        let calendar = Calendar.current

        // Update streak
        if calendar.isDateInToday(lastActivityDate) {
            // Same day, no streak change
        } else if calendar.isDateInYesterday(lastActivityDate) {
            // Consecutive day, increment streak
            currentStreak += 1
            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        } else {
            // Streak broken, reset
            currentStreak = 1
        }

        lastActivityDate = now
        lastStreakDate = now
    }

    /// Reset daily counters (call at midnight)
    mutating func resetDaily() {
        repliesToday = 0
    }

    /// Reset weekly counters (call on Monday)
    mutating func resetWeekly() {
        repliesThisWeek = 0
    }

    /// Reset monthly counters (call on 1st)
    mutating func resetMonthly() {
        repliesThisMonth = 0
    }

    // MARK: - Statistics

    /**
     LEARNING: Statistical Methods
     ==============================
     Provide insights for analytics dashboard
     */

    /// Get usage summary for display
    func usageSummary() -> UsageSummary {
        UsageSummary(
            totalReplies: totalRepliesGenerated,
            repliesToday: repliesToday,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            averageSatisfaction: averageSatisfaction,
            mostUsedTone: mostUsedTone,
            mostUsedPlatform: mostUsedPlatform,
            engagementLevel: engagementLevel
        )
    }

    /// Get tone breakdown for charts
    func toneBreakdown() -> [(Tone, Int)] {
        toneUsage.sorted { $0.value > $1.value }
    }

    /// Get platform breakdown for charts
    func platformBreakdown() -> [(Platform, Int)] {
        platformUsage.sorted { $0.value > $1.value }
    }
}

// MARK: - Supporting Types

/**
 LEARNING: Supporting Enums
 ==========================
 Define clear levels/states
 Type-safe categorization
 */

enum EngagementLevel: String, Codable {
    case powerUser = "powerUser"
    case active = "active"
    case casual = "casual"
    case inactive = "inactive"

    var displayName: String {
        switch self {
        case .powerUser: return "Power User"
        case .active: return "Active"
        case .casual: return "Casual"
        case .inactive: return "Inactive"
        }
    }

    var emoji: String {
        switch self {
        case .powerUser: return "🔥"
        case .active: return "✅"
        case .casual: return "👍"
        case .inactive: return "💤"
        }
    }

    var description: String {
        switch self {
        case .powerUser: return "Uses the app daily, 10+ replies per day"
        case .active: return "Regular user, 5-10 replies per day"
        case .casual: return "Occasional user, 1-5 replies per day"
        case .inactive: return "Rarely uses the app"
        }
    }
}

/**
 Usage summary for UI display
 */
struct UsageSummary {
    let totalReplies: Int
    let repliesToday: Int
    let currentStreak: Int
    let longestStreak: Int
    let averageSatisfaction: Double
    let mostUsedTone: Tone?
    let mostUsedPlatform: Platform?
    let engagementLevel: EngagementLevel
}

// MARK: - Codable Implementation

extension UsageMetrics {
    /**
     LEARNING: Custom Codable for Dictionaries
     ==========================================
     Swift can't auto-synthesize Codable for dictionaries with enum keys
     Need custom implementation
     */

    private enum CodingKeys: String, CodingKey {
        case userId
        case totalRepliesGenerated
        case repliesToday
        case repliesThisWeek
        case repliesThisMonth
        case toneUsage
        case platformUsage
        case averageResponseTime
        case copiedCount
        case editedCount
        case satisfactionRatings
        case lastActivityDate
        case accountCreatedDate
        case currentStreak
        case longestStreak
        case lastStreakDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        userId = try container.decode(String.self, forKey: .userId)
        totalRepliesGenerated = try container.decode(Int.self, forKey: .totalRepliesGenerated)
        repliesToday = try container.decode(Int.self, forKey: .repliesToday)
        repliesThisWeek = try container.decode(Int.self, forKey: .repliesThisWeek)
        repliesThisMonth = try container.decode(Int.self, forKey: .repliesThisMonth)
        averageResponseTime = try container.decode(Double.self, forKey: .averageResponseTime)
        copiedCount = try container.decode(Int.self, forKey: .copiedCount)
        editedCount = try container.decode(Int.self, forKey: .editedCount)
        satisfactionRatings = try container.decode([Int].self, forKey: .satisfactionRatings)
        lastActivityDate = try container.decode(Date.self, forKey: .lastActivityDate)
        accountCreatedDate = try container.decode(Date.self, forKey: .accountCreatedDate)
        currentStreak = try container.decode(Int.self, forKey: .currentStreak)
        longestStreak = try container.decode(Int.self, forKey: .longestStreak)
        lastStreakDate = try container.decode(Date.self, forKey: .lastStreakDate)

        // Decode tone usage
        let toneDict = try container.decode([String: Int].self, forKey: .toneUsage)
        toneUsage = toneDict.reduce(into: [:]) { result, pair in
            if let tone = Tone(rawValue: pair.key) {
                result[tone] = pair.value
            }
        }

        // Decode platform usage
        let platformDict = try container.decode([String: Int].self, forKey: .platformUsage)
        platformUsage = platformDict.reduce(into: [:]) { result, pair in
            if let platform = Platform(rawValue: pair.key) {
                result[platform] = pair.value
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(userId, forKey: .userId)
        try container.encode(totalRepliesGenerated, forKey: .totalRepliesGenerated)
        try container.encode(repliesToday, forKey: .repliesToday)
        try container.encode(repliesThisWeek, forKey: .repliesThisWeek)
        try container.encode(repliesThisMonth, forKey: .repliesThisMonth)
        try container.encode(averageResponseTime, forKey: .averageResponseTime)
        try container.encode(copiedCount, forKey: .copiedCount)
        try container.encode(editedCount, forKey: .editedCount)
        try container.encode(satisfactionRatings, forKey: .satisfactionRatings)
        try container.encode(lastActivityDate, forKey: .lastActivityDate)
        try container.encode(accountCreatedDate, forKey: .accountCreatedDate)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(longestStreak, forKey: .longestStreak)
        try container.encode(lastStreakDate, forKey: .lastStreakDate)

        // Encode tone usage
        let toneDict = toneUsage.reduce(into: [:]) { result, pair in
            result[pair.key.rawValue] = pair.value
        }
        try container.encode(toneDict, forKey: .toneUsage)

        // Encode platform usage
        let platformDict = platformUsage.reduce(into: [:]) { result, pair in
            result[pair.key.rawValue] = pair.value
        }
        try container.encode(platformDict, forKey: .platformUsage)
    }
}

// MARK: - Extensions

extension UsageMetrics {
    /// Sample metrics for testing/previews
    static func sample() -> UsageMetrics {
        var metrics = UsageMetrics(userId: "sample-user-123")
        metrics.totalRepliesGenerated = 156
        metrics.repliesToday = 8
        metrics.repliesThisWeek = 42
        metrics.repliesThisMonth = 156
        metrics.toneUsage = [
            .friendly: 80,
            .professional: 45,
            .funny: 20,
            .flirty: 11
        ]
        metrics.platformUsage = [
            .whatsapp: 70,
            .imessage: 40,
            .outlook: 30,
            .instagram: 10,
            .slack: 5,
            .teams: 1
        ]
        metrics.copiedCount = 120
        metrics.editedCount = 25
        metrics.satisfactionRatings = [5, 5, 4, 5, 4, 5, 5]
        metrics.currentStreak = 7
        metrics.longestStreak = 14
        return metrics
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. Analytics Tracking
    - Record user actions
    - Calculate insights
    - Measure engagement
    - Identify patterns

 2. Rolling Averages
    - Update incrementally
    - No need to store all data
    - Efficient calculation

 3. Streak Tracking
    - Check date continuity
    - Update on activity
    - Gamification element

 4. Engagement Levels
    - Categorize users
    - Target interventions
    - Predict churn

 5. Privacy-First Analytics
    - Aggregate data only
    - User can opt-out
    - No personal information
    - GDPR compliant

 6. Performance Optimization
    - Limit array sizes (last 100 ratings)
    - Computed properties (not stored)
    - Efficient dictionary operations

 FIREBASE STORAGE:
 =================
 Store at: /users/{userId}/metrics

 Update strategy:
 - Real-time for active session
 - Batch upload on app close
 - Sync on app open

 USAGE EXAMPLE:
 ==============
 ```swift
 var metrics = UsageMetrics(userId: "user123")

 // Record new reply
 metrics.recordReply(
     tone: .friendly,
     platform: .whatsapp,
     responseTime: 1.2
 )

 // Record copy action
 metrics.recordCopy()

 // Record satisfaction
 metrics.recordSatisfaction(rating: 5)

 // Get insights
 let summary = metrics.usageSummary()
 print("Total replies: \\(summary.totalReplies)")
 print("Engagement: \\(summary.engagementLevel.emoji)")

 // Check engagement
 if metrics.isChurnRisk {
     // Show re-engagement prompt
 }

 // Get chart data
 let toneData = metrics.toneBreakdown()
 // Display in pie chart
 ```

 NEXT STEPS:
 ===========
 - Use in AnalyticsService for Firebase sync
 - Display in HistoryView
 - Show in SettingsView stats section
 - Use for A/B testing
 */
