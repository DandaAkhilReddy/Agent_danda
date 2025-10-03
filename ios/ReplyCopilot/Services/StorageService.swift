import Foundation

/**
 StorageService - Local Data Persistence

 LEARNING: iOS Storage Options
 ==============================
 iOS has multiple storage mechanisms:

 1. UserDefaults
    - Small key-value data
    - User preferences
    - App settings
    - NOT secure (plain text)
    - Max ~1MB recommended

 2. Keychain
    - Secure storage
    - Passwords, tokens
    - Hardware encrypted
    - Survives app deletion

 3. FileManager
    - Large files
    - Documents, images
    - User generated content

 4. CoreData / SQLite
    - Structured data
    - Complex queries
    - Relationships

 5. App Groups
    - Share data between targets
    - Main app + Extensions
    - Shared UserDefaults/Files

 This service wraps UserDefaults, Keychain, and App Groups
 */

@MainActor
class StorageService: ObservableObject {

    // MARK: - Singleton

    static let shared = StorageService()

    // MARK: - Properties

    /**
     LEARNING: UserDefaults Suites
     ==============================
     standard: App-specific storage
     suiteName: Shared storage (App Groups)
     */

    /// Standard UserDefaults (app-only)
    private let defaults: UserDefaults

    /// Shared UserDefaults (app + extensions)
    private let sharedDefaults: UserDefaults?

    // MARK: - Initialization

    private init() {
        self.defaults = UserDefaults.standard

        // Try to initialize shared defaults with App Group
        if let groupDefaults = UserDefaults(suiteName: Config.appGroupIdentifier) {
            self.sharedDefaults = groupDefaults
            print("✅ App Group storage initialized")
        } else {
            self.sharedDefaults = nil
            print("⚠️ App Group not configured")
        }
    }

    // MARK: - User Preferences

    /**
     LEARNING: @AppStorage
     ======================
     SwiftUI property wrapper for UserDefaults
     Automatically updates UI when value changes
     But we provide service methods for non-SwiftUI code
     */

    /// Save user preferences
    func savePreferences(_ preferences: UserPreferences) throws {
        let data = try JSONEncoder().encode(preferences)
        defaults.set(data, forKey: Keys.userPreferences)
        sharedDefaults?.set(data, forKey: Keys.userPreferences)
    }

    /// Load user preferences
    func loadPreferences() -> UserPreferences? {
        guard let data = defaults.data(forKey: Keys.userPreferences) else {
            return nil
        }

        return try? JSONDecoder().decode(UserPreferences.self, from: data)
    }

    /// Delete user preferences
    func deletePreferences() {
        defaults.removeObject(forKey: Keys.userPreferences)
        sharedDefaults?.removeObject(forKey: Keys.userPreferences)
    }

    // MARK: - Usage Metrics

    /// Save usage metrics
    func saveMetrics(_ metrics: UsageMetrics) throws {
        let data = try JSONEncoder().encode(metrics)
        defaults.set(data, forKey: Keys.usageMetrics)
    }

    /// Load usage metrics
    func loadMetrics() -> UsageMetrics? {
        guard let data = defaults.data(forKey: Keys.usageMetrics) else {
            return nil
        }

        return try? JSONDecoder().decode(UsageMetrics.self, from: data)
    }

    // MARK: - Reply History

    /**
     LEARNING: Array Storage in UserDefaults
     ========================================
     Can store arrays of Codable objects
     Encode to Data, store as Data
     Retrieve and decode back to array
     */

    /// Save reply history
    func saveHistory(_ suggestions: [ReplySuggestion]) throws {
        let data = try JSONEncoder().encode(suggestions)
        defaults.set(data, forKey: Keys.replyHistory)
        sharedDefaults?.set(data, forKey: Keys.replyHistory)
    }

    /// Load reply history
    func loadHistory() -> [ReplySuggestion] {
        guard let data = defaults.data(forKey: Keys.replyHistory) else {
            return []
        }

        return (try? JSONDecoder().decode([ReplySuggestion].self, from: data)) ?? []
    }

    /// Add suggestion to history
    func addToHistory(_ suggestion: ReplySuggestion) throws {
        var history = loadHistory()
        history.insert(suggestion, at: 0) // Add to beginning

        // Keep only last 100 suggestions
        if history.count > 100 {
            history = Array(history.prefix(100))
        }

        try saveHistory(history)
    }

    /// Delete from history
    func deleteFromHistory(_ suggestion: ReplySuggestion) throws {
        var history = loadHistory()
        history.removeAll { $0.id == suggestion.id }
        try saveHistory(history)
    }

    /// Clear all history
    func clearHistory() {
        defaults.removeObject(forKey: Keys.replyHistory)
        sharedDefaults?.removeObject(forKey: Keys.replyHistory)
    }

    // MARK: - App Settings

    /**
     LEARNING: Simple Value Storage
     ===============================
     UserDefaults has built-in methods for common types:
     - set(_:forKey:) for Bool, Int, Double, String, Data, Array, Dictionary
     - object(forKey:) returns Any?
     - bool(forKey:), integer(forKey:), etc. for specific types
     */

    /// Has user completed onboarding?
    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasCompletedOnboarding) }
        set {
            defaults.set(newValue, forKey: Keys.hasCompletedOnboarding)
            sharedDefaults?.set(newValue, forKey: Keys.hasCompletedOnboarding)
        }
    }

    /// Last sync timestamp
    var lastSyncDate: Date? {
        get { defaults.object(forKey: Keys.lastSyncDate) as? Date }
        set {
            defaults.set(newValue, forKey: Keys.lastSyncDate)
            sharedDefaults?.set(newValue, forKey: Keys.lastSyncDate)
        }
    }

    /// App version (for migrations)
    var appVersion: String {
        get { defaults.string(forKey: Keys.appVersion) ?? "" }
        set {
            defaults.set(newValue, forKey: Keys.appVersion)
        }
    }

    /// Selected theme
    var selectedTheme: String {
        get { defaults.string(forKey: Keys.selectedTheme) ?? "system" }
        set {
            defaults.set(newValue, forKey: Keys.selectedTheme)
        }
    }

    /// Haptic feedback enabled
    var hapticFeedbackEnabled: Bool {
        get { defaults.bool(forKey: Keys.hapticFeedbackEnabled) }
        set {
            defaults.set(newValue, forKey: Keys.hapticFeedbackEnabled)
        }
    }

    // MARK: - Keychain Integration

    /**
     LEARNING: Keychain vs UserDefaults
     ===================================
     Use Keychain for:
     - Passwords
     - API tokens
     - Authentication credentials
     - Encryption keys

     Use UserDefaults for:
     - App preferences
     - UI state
     - Non-sensitive data
     */

    /// Save API token to keychain
    func saveApiToken(_ token: String) throws {
        try KeychainItem.sharedApiToken.save(token)
    }

    /// Load API token from keychain
    func loadApiToken() -> String? {
        try? KeychainItem.sharedApiToken.readString()
    }

    /// Delete API token
    func deleteApiToken() throws {
        try KeychainItem.sharedApiToken.delete()
    }

    /// Save user ID to keychain
    func saveUserId(_ userId: String) throws {
        try KeychainItem.sharedUserId.save(userId)
    }

    /// Load user ID from keychain
    func loadUserId() -> String? {
        try? KeychainItem.sharedUserId.readString()
    }

    /// Delete user ID
    func deleteUserId() throws {
        try KeychainItem.sharedUserId.delete()
    }

    // MARK: - App Groups (Extensions)

    /**
     LEARNING: App Groups
     ====================
     Share data between:
     - Main app
     - Share extension
     - Keyboard extension

     Set up in Xcode:
     1. Add App Groups capability
     2. Enable same group for all targets
     3. Use group identifier in code
     */

    /// Save latest suggestions for extensions
    func saveSuggestionsForExtensions(_ suggestions: [ReplySuggestion]) throws {
        guard let sharedDefaults = sharedDefaults else {
            throw StorageError.appGroupNotConfigured
        }

        let data = try JSONEncoder().encode(suggestions)
        sharedDefaults.set(data, forKey: Keys.latestSuggestions)
        sharedDefaults.synchronize() // Force write
    }

    /// Load latest suggestions from extensions
    func loadSuggestionsFromExtensions() -> [ReplySuggestion] {
        guard let sharedDefaults = sharedDefaults,
              let data = sharedDefaults.data(forKey: Keys.latestSuggestions) else {
            return []
        }

        return (try? JSONDecoder().decode([ReplySuggestion].self, from: data)) ?? []
    }

    /// Share platform/tone selection with extensions
    func saveSelectionForExtensions(platform: Platform, tone: Tone) {
        sharedDefaults?.set(platform.rawValue, forKey: Keys.selectedPlatform)
        sharedDefaults?.set(tone.rawValue, forKey: Keys.selectedTone)
        sharedDefaults?.synchronize()
    }

    /// Load platform/tone selection from extensions
    func loadSelectionFromExtensions() -> (platform: Platform?, tone: Tone?) {
        guard let sharedDefaults = sharedDefaults else {
            return (nil, nil)
        }

        let platformString = sharedDefaults.string(forKey: Keys.selectedPlatform)
        let toneString = sharedDefaults.string(forKey: Keys.selectedTone)

        let platform = platformString.flatMap { Platform(rawValue: $0) }
        let tone = toneString.flatMap { Tone(rawValue: $0) }

        return (platform, tone)
    }

    // MARK: - Data Migration

    /**
     LEARNING: Data Migration
     ========================
     When app structure changes:
     - Add version tracking
     - Check version on launch
     - Migrate old data format
     - Update version number
     */

    /// Check if migration is needed
    func needsMigration() -> Bool {
        let currentVersion = Config.appVersion
        let storedVersion = appVersion

        return storedVersion != currentVersion
    }

    /// Perform data migration
    func migrate() throws {
        let currentVersion = Config.appVersion
        let storedVersion = appVersion

        print("📦 Migrating from \(storedVersion) to \(currentVersion)")

        // Example migrations
        if storedVersion.isEmpty {
            // First install, no migration needed
            print("✅ First install detected")
        } else if storedVersion < "2.0.0" {
            // Migrate from 1.x to 2.0
            print("🔄 Migrating from 1.x to 2.0")
            // Perform migration tasks
        }

        // Update stored version
        appVersion = currentVersion
        print("✅ Migration complete")
    }

    // MARK: - Cleanup

    /// Clear all app data (for sign out or account deletion)
    func clearAllData() throws {
        // Clear UserDefaults
        if let bundleId = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleId)
        }

        // Clear shared UserDefaults
        if let sharedDefaults = sharedDefaults {
            sharedDefaults.removePersistentDomain(forName: Config.appGroupIdentifier)
        }

        // Clear Keychain
        try? deleteApiToken()
        try? deleteUserId()

        print("🗑️ All data cleared")
    }

    /// Clear cache only (keep user settings)
    func clearCache() {
        clearHistory()
        lastSyncDate = nil
        print("🗑️ Cache cleared")
    }
}

// MARK: - Storage Keys

/**
 LEARNING: Centralized Keys
 ==========================
 Define all UserDefaults keys in one place
 Prevents typos
 Easy to refactor
 Type-safe with enum
 */

private enum Keys {
    static let userPreferences = "userPreferences"
    static let usageMetrics = "usageMetrics"
    static let replyHistory = "replyHistory"
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let lastSyncDate = "lastSyncDate"
    static let appVersion = "appVersion"
    static let selectedTheme = "selectedTheme"
    static let hapticFeedbackEnabled = "hapticFeedbackEnabled"
    static let latestSuggestions = "latestSuggestions"
    static let selectedPlatform = "selectedPlatform"
    static let selectedTone = "selectedTone"
}

// MARK: - Storage Error

enum StorageError: Error, LocalizedError {
    case appGroupNotConfigured
    case encodingFailed
    case decodingFailed
    case keychainError(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .appGroupNotConfigured:
            return "App Group Not Configured"
        case .encodingFailed:
            return "Failed to Encode Data"
        case .decodingFailed:
            return "Failed to Decode Data"
        case .keychainError(let error):
            return "Keychain Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - SwiftUI Property Wrappers

/**
 LEARNING: @AppStorage
 =====================
 SwiftUI property wrapper for UserDefaults
 Automatically updates view when value changes
 Use in SwiftUI views for reactive storage
 */

extension StorageService {
    /// Example of providing @AppStorage-compatible keys
    static let onboardingKey = Keys.hasCompletedOnboarding
    static let themeKey = Keys.selectedTheme
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. iOS Storage Options
    - UserDefaults: Small key-value data
    - Keychain: Secure storage
    - FileManager: Large files
    - App Groups: Share between targets

 2. UserDefaults
    - Plist-based storage
    - Key-value pairs
    - Automatic synchronization
    - NOT secure

 3. App Groups
    - Share data between main app and extensions
    - Shared UserDefaults suite
    - Shared file container
    - Configure in Xcode capabilities

 4. Data Migration
    - Track app version
    - Migrate on version change
    - Maintain backwards compatibility

 5. Codable Storage
    - Encode objects to Data
    - Store in UserDefaults
    - Decode back to objects
    - Type-safe

 6. Keychain Integration
    - Secure storage for sensitive data
    - Separate service (KeychainItem)
    - Hardware encrypted

 USAGE EXAMPLE:
 ==============
 ```swift
 let storage = StorageService.shared

 // Save preferences
 var prefs = UserPreferences(userId: "user123")
 try storage.savePreferences(prefs)

 // Load preferences
 if let prefs = storage.loadPreferences() {
     print("Default tone: \\(prefs.defaultTone)")
 }

 // Add to history
 let suggestion = ReplySuggestion(...)
 try storage.addToHistory(suggestion)

 // Load history
 let history = storage.loadHistory()
 print("\\(history.count) past replies")

 // App settings
 storage.hasCompletedOnboarding = true
 storage.selectedTheme = "dark"

 // Token management
 try storage.saveApiToken("abc123")
 if let token = storage.loadApiToken() {
     print("Token: \\(token)")
 }

 // Share with extensions
 try storage.saveSuggestionsForExtensions([suggestion1, suggestion2])
 storage.saveSelectionForExtensions(platform: .whatsapp, tone: .friendly)

 // Cleanup
 try storage.clearAllData()
 ```

 SWIFTUI INTEGRATION:
 ===================
 ```swift
 struct SettingsView: View {
     // Direct UserDefaults access
     @AppStorage(StorageService.onboardingKey) var hasCompletedOnboarding = false
     @AppStorage(StorageService.themeKey) var theme = "system"

     // Or use service
     @StateObject private var storage = StorageService.shared

     var body: some View {
         Form {
             Toggle("Haptic Feedback", isOn: $storage.hapticFeedbackEnabled)

             Picker("Theme", selection: $theme) {
                 Text("System").tag("system")
                 Text("Light").tag("light")
                 Text("Dark").tag("dark")
             }
         }
     }
 }
 ```

 EXTENSION USAGE:
 ================
 ```swift
 // In Share Extension
 let storage = StorageService.shared

 // Load user preferences (shared via App Group)
 if let prefs = storage.loadPreferences() {
     let defaultTone = prefs.defaultTone
     // Use in API call
 }

 // Save suggestions for keyboard extension
 try storage.saveSuggestionsForExtensions(suggestions)

 // In Keyboard Extension
 let suggestions = storage.loadSuggestionsFromExtensions()
 // Display in keyboard UI
 ```

 DATA MIGRATION:
 ==============
 ```swift
 // On app launch
 if storage.needsMigration() {
     try storage.migrate()
 }
 ```

 NEXT STEPS:
 ===========
 - Configure App Groups in Xcode
 - Use in SettingsView
 - Use in extensions
 - Add FileManager for large files
 - Add CoreData for complex queries
 */
