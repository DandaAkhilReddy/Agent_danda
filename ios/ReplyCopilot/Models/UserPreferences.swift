import Foundation

/**
 UserPreferences - User Settings Model

 LEARNING: Structs vs Classes
 ============================
 We use a struct here because:
 - Value type (copies are safe)
 - No inheritance needed
 - Codable works perfectly
 - Lightweight and fast
 - Thread-safe by default

 WHY not a class?
 - Classes are reference types (shared state)
 - Unnecessary overhead for simple data
 - Requires manual Codable implementation
 - Memory management concerns

 RULE OF THUMB:
 - Use structs for data models
 - Use classes for services, managers, coordinators
 */

struct UserPreferences: Codable, Equatable {

    // MARK: - Properties

    /**
     LEARNING: Property Types
     ========================
     - let: Immutable (can't change after init)
     - var: Mutable (can change)

     Best practice: Use 'let' by default, 'var' only when needed
     */

    /// Unique user identifier from Firebase Auth
    let userId: String

    /// Default tone for new reply generations
    var defaultTone: Tone

    /// Per-platform tone preferences
    /// LEARNING: Dictionary for key-value storage
    var platformPreferences: [Platform: Tone]

    /// User's preferred language (ISO 639-1 code)
    var language: String

    /// Subscription tier
    var subscriptionTier: SubscriptionTier

    /// Daily usage count (resets at midnight)
    var dailyUsageCount: Int

    /// Last usage reset date
    var lastResetDate: Date

    /// Notification settings
    var notificationSettings: NotificationSettings

    /// Privacy settings
    var privacySettings: PrivacySettings

    /// App version when preferences were last updated
    var appVersion: String

    /// Last sync timestamp with Firebase
    var lastSyncedAt: Date

    // MARK: - Nested Types

    /**
     LEARNING: Nested Structs
     ========================
     Group related settings together
     Keeps UserPreferences namespace clean
     Makes it clear these belong to UserPreferences
     */

    struct NotificationSettings: Codable, Equatable {
        var dailyLimitWarning: Bool
        var newFeatures: Bool
        var weeklyDigest: Bool
        var soundEnabled: Bool

        static let `default` = NotificationSettings(
            dailyLimitWarning: true,
            newFeatures: true,
            weeklyDigest: false,
            soundEnabled: true
        )
    }

    struct PrivacySettings: Codable, Equatable {
        var analyticsEnabled: Bool
        var crashReportingEnabled: Bool
        var personalizedSuggestions: Bool

        static let `default` = PrivacySettings(
            analyticsEnabled: true,
            crashReportingEnabled: true,
            personalizedSuggestions: true
        )
    }

    // MARK: - Initialization

    /**
     LEARNING: Custom Initializers
     ==============================
     Swift auto-generates memberwise initializers
     But we create custom ones for convenience
     */

    /// Create new user preferences with defaults
    init(userId: String) {
        self.userId = userId
        self.defaultTone = .friendly
        self.platformPreferences = Self.defaultPlatformPreferences
        self.language = Locale.current.languageCode ?? "en"
        self.subscriptionTier = .free
        self.dailyUsageCount = 0
        self.lastResetDate = Date()
        self.notificationSettings = .default
        self.privacySettings = .default
        self.appVersion = Config.appVersion
        self.lastSyncedAt = Date()
    }

    /// Full initializer for decoding from Firebase
    init(
        userId: String,
        defaultTone: Tone,
        platformPreferences: [Platform: Tone],
        language: String,
        subscriptionTier: SubscriptionTier,
        dailyUsageCount: Int,
        lastResetDate: Date,
        notificationSettings: NotificationSettings,
        privacySettings: PrivacySettings,
        appVersion: String,
        lastSyncedAt: Date
    ) {
        self.userId = userId
        self.defaultTone = defaultTone
        self.platformPreferences = platformPreferences
        self.language = language
        self.subscriptionTier = subscriptionTier
        self.dailyUsageCount = dailyUsageCount
        self.lastResetDate = lastResetDate
        self.notificationSettings = notificationSettings
        self.privacySettings = privacySettings
        self.appVersion = appVersion
        self.lastSyncedAt = lastSyncedAt
    }

    // MARK: - Default Values

    /**
     LEARNING: Static Properties
     ============================
     Belong to the type, not an instance
     Use 'Self' to refer to current type
     */

    /// Default platform tone mappings
    static let defaultPlatformPreferences: [Platform: Tone] = [
        .whatsapp: .friendly,
        .imessage: .friendly,
        .instagram: .funny,
        .outlook: .professional,
        .slack: .friendly,
        .teams: .professional
    ]

    // MARK: - Computed Properties

    /**
     LEARNING: Computed Properties
     ==============================
     Calculate value on access
     No stored value in memory
     Always up-to-date
     */

    /// Whether user has reached daily limit
    var hasReachedDailyLimit: Bool {
        guard subscriptionTier == .free else {
            return false // Pro users have unlimited
        }
        return dailyUsageCount >= Config.freeTierDailyLimit
    }

    /// Remaining replies today
    var remainingReplies: Int {
        guard subscriptionTier == .free else {
            return Int.max // Unlimited for pro
        }
        return max(0, Config.freeTierDailyLimit - dailyUsageCount)
    }

    /// Percentage of daily limit used
    var dailyLimitPercentage: Double {
        guard subscriptionTier == .free else {
            return 0.0
        }
        return Double(dailyUsageCount) / Double(Config.freeTierDailyLimit)
    }

    /// Whether usage needs reset (new day)
    var needsUsageReset: Bool {
        !Calendar.current.isDateInToday(lastResetDate)
    }

    /// Whether user is on free tier
    var isFreeUser: Bool {
        subscriptionTier == .free
    }

    /// Whether user is on pro tier
    var isProUser: Bool {
        subscriptionTier == .pro
    }

    // MARK: - Methods

    /**
     LEARNING: Mutating Methods
     ==========================
     Structs are value types (immutable by default)
     'mutating' keyword allows modification
     Creates a new copy with changes
     */

    /// Increment daily usage count
    mutating func incrementUsage() {
        // Reset if it's a new day
        if needsUsageReset {
            resetDailyUsage()
        }
        dailyUsageCount += 1
        lastSyncedAt = Date()
    }

    /// Reset daily usage count
    mutating func resetDailyUsage() {
        dailyUsageCount = 0
        lastResetDate = Date()
        lastSyncedAt = Date()
    }

    /// Update subscription tier
    mutating func updateSubscription(to tier: SubscriptionTier) {
        subscriptionTier = tier
        lastSyncedAt = Date()
    }

    /// Set tone preference for a platform
    mutating func setTone(_ tone: Tone, for platform: Platform) {
        platformPreferences[platform] = tone
        lastSyncedAt = Date()
    }

    /// Get tone preference for a platform (falls back to default)
    func getTone(for platform: Platform) -> Tone {
        platformPreferences[platform] ?? defaultTone
    }

    /// Update app version
    mutating func updateAppVersion(_ version: String) {
        appVersion = version
        lastSyncedAt = Date()
    }

    /// Mark as synced
    mutating func markSynced() {
        lastSyncedAt = Date()
    }

    // MARK: - Validation

    /**
     LEARNING: Validation Methods
     =============================
     Return Result type for success/failure
     Provides clear error messages
     */

    /// Validate preferences
    func validate() -> Result<Void, ValidationError> {
        // Check user ID
        guard !userId.isEmpty else {
            return .failure(.invalidUserId)
        }

        // Check language code
        guard language.count == 2 else {
            return .failure(.invalidLanguageCode)
        }

        // Check daily usage
        guard dailyUsageCount >= 0 else {
            return .failure(.invalidUsageCount)
        }

        return .success(())
    }

    enum ValidationError: LocalizedError {
        case invalidUserId
        case invalidLanguageCode
        case invalidUsageCount

        var errorDescription: String? {
            switch self {
            case .invalidUserId:
                return "User ID cannot be empty"
            case .invalidLanguageCode:
                return "Language code must be 2 characters (ISO 639-1)"
            case .invalidUsageCount:
                return "Daily usage count cannot be negative"
            }
        }
    }

    // MARK: - Codable

    /**
     LEARNING: Codable Protocol
     ===========================
     Swift auto-synthesizes Codable for structs
     But dictionaries with enum keys need custom implementation
     CodingKeys controls JSON field names
     */

    private enum CodingKeys: String, CodingKey {
        case userId
        case defaultTone
        case platformPreferences
        case language
        case subscriptionTier
        case dailyUsageCount
        case lastResetDate
        case notificationSettings
        case privacySettings
        case appVersion
        case lastSyncedAt
    }

    /// Custom decoder for platformPreferences dictionary
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        userId = try container.decode(String.self, forKey: .userId)
        defaultTone = try container.decode(Tone.self, forKey: .defaultTone)
        language = try container.decode(String.self, forKey: .language)
        subscriptionTier = try container.decode(SubscriptionTier.self, forKey: .subscriptionTier)
        dailyUsageCount = try container.decode(Int.self, forKey: .dailyUsageCount)
        lastResetDate = try container.decode(Date.self, forKey: .lastResetDate)
        notificationSettings = try container.decode(NotificationSettings.self, forKey: .notificationSettings)
        privacySettings = try container.decode(PrivacySettings.self, forKey: .privacySettings)
        appVersion = try container.decode(String.self, forKey: .appVersion)
        lastSyncedAt = try container.decode(Date.self, forKey: .lastSyncedAt)

        // Decode platform preferences dictionary
        // Convert from [String: String] to [Platform: Tone]
        let platformDict = try container.decode([String: String].self, forKey: .platformPreferences)
        platformPreferences = platformDict.compactMapValues { toneString in
            Tone(rawValue: toneString)
        }.reduce(into: [:]) { result, pair in
            if let platform = Platform(rawValue: pair.key) {
                result[platform] = pair.value
            }
        }
    }

    /// Custom encoder for platformPreferences dictionary
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(userId, forKey: .userId)
        try container.encode(defaultTone, forKey: .defaultTone)
        try container.encode(language, forKey: .language)
        try container.encode(subscriptionTier, forKey: .subscriptionTier)
        try container.encode(dailyUsageCount, forKey: .dailyUsageCount)
        try container.encode(lastResetDate, forKey: .lastResetDate)
        try container.encode(notificationSettings, forKey: .notificationSettings)
        try container.encode(privacySettings, forKey: .privacySettings)
        try container.encode(appVersion, forKey: .appVersion)
        try container.encode(lastSyncedAt, forKey: .lastSyncedAt)

        // Encode platform preferences dictionary
        // Convert from [Platform: Tone] to [String: String]
        let platformDict = platformPreferences.reduce(into: [:]) { result, pair in
            result[pair.key.rawValue] = pair.value.rawValue
        }
        try container.encode(platformDict, forKey: .platformPreferences)
    }
}

// MARK: - SubscriptionTier

/**
 LEARNING: Subscription Model
 =============================
 Simple enum for different tiers
 Can be extended with associated values for more complex plans
 */

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        }
    }

    var dailyLimit: Int? {
        switch self {
        case .free: return 20
        case .pro: return nil // Unlimited
        }
    }

    var price: String {
        switch self {
        case .free: return "$0"
        case .pro: return "$9.99/month"
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "20 replies per day",
                "4 tone styles",
                "6 platform adapters",
                "Basic support"
            ]
        case .pro:
            return [
                "Unlimited replies",
                "4 tone styles",
                "6 platform adapters",
                "Priority support",
                "Advanced analytics",
                "Custom tones (coming soon)"
            ]
        }
    }
}

// MARK: - Extensions

extension UserPreferences {

    /**
     LEARNING: Factory Methods
     ==========================
     Convenient ways to create instances
     Better than having many initializers
     */

    /// Create sample preferences for previews/testing
    static func sample(userId: String = "sample-user-123") -> UserPreferences {
        var prefs = UserPreferences(userId: userId)
        prefs.dailyUsageCount = 8
        prefs.subscriptionTier = .free
        return prefs
    }

    /// Create pro user preferences
    static func proSample(userId: String = "pro-user-123") -> UserPreferences {
        var prefs = UserPreferences(userId: userId)
        prefs.subscriptionTier = .pro
        prefs.dailyUsageCount = 150
        return prefs
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. Structs vs Classes
    - Structs for data models (value types)
    - Classes for services (reference types)
    - Structs are thread-safe by default

 2. Property Types
    - let: Immutable
    - var: Mutable
    - Computed properties (calculated on access)

 3. Mutating Methods
    - Required for struct methods that modify properties
    - Creates new copy with changes
    - Value semantics

 4. Nested Types
    - Group related types together
    - Clean namespace
    - Clear ownership

 5. Custom Codable
    - Auto-synthesis for simple types
    - Custom implementation for dictionaries with enum keys
    - CodingKeys for JSON field mapping

 6. Validation
    - Result type for success/failure
    - Clear error messages
    - Guard statements for early returns

 7. Default Values
    - Static properties for defaults
    - Factory methods for common instances
    - Type-safe constants

 FIREBASE INTEGRATION:
 ====================
 This model will be stored in Firestore at:
 /users/{userId}/preferences

 Firestore will automatically convert:
 - Dates to Timestamp
 - Enums to String
 - Nested structs to Maps

 USAGE EXAMPLE:
 ==============
 ```swift
 // Create new user preferences
 var prefs = UserPreferences(userId: "user123")

 // Increment usage
 prefs.incrementUsage()

 // Check limit
 if prefs.hasReachedDailyLimit {
     print("Show upgrade prompt")
 }

 // Set platform preference
 prefs.setTone(.professional, for: .outlook)

 // Get tone for platform
 let tone = prefs.getTone(for: .whatsapp)

 // Upgrade to pro
 prefs.updateSubscription(to: .pro)

 // Validate
 switch prefs.validate() {
 case .success:
     // Save to Firebase
     break
 case .failure(let error):
     print(error.localizedDescription)
 }
 ```

 NEXT STEPS:
 ===========
 - See AuthService.swift for Firebase integration
 - See StorageService.swift for local caching
 - Use in SettingsView for UI
 */
