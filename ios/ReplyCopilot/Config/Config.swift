import Foundation

/// ReplyCopilot Configuration
/// Central configuration for all app settings
struct Config {

    // MARK: - Environment

    #if DEBUG
    static let environment = Environment.development
    #else
    static let environment = Environment.production
    #endif

    enum Environment {
        case development
        case staging
        case production

        var baseURL: String {
            switch self {
            case .development:
                return "http://localhost:7071"
            case .staging:
                return "https://replycopilot-api-2025.azurewebsites.net"
            case .production:
                return "https://replycopilot-api-2025.azurewebsites.net"
            }
        }

        var name: String {
            switch self {
            case .development: return "Development"
            case .staging: return "Staging"
            case .production: return "Production"
            }
        }
    }

    // MARK: - API Configuration

    /// Base URL for API requests (automatically set based on environment)
    static let baseURL = environment.baseURL

    /// Azure Function API key
    /// TODO: Replace with your actual function key after deployment
    /// Get from: Azure Portal → replycopilot-api-2025 → Functions → generateReplies → Function Keys
    static let apiKey = "REPLACE_WITH_YOUR_FUNCTION_KEY"

    /// API version
    static let apiVersion = "1.0"

    /// Request timeout (in seconds)
    static let timeout: TimeInterval = 30

    // MARK: - Endpoints

    struct Endpoints {
        static let generateReplies = "/api/generateReplies"
        static let health = "/api/health"
    }

    // MARK: - Azure OpenAI Configuration

    struct AzureOpenAI {
        static let deployment = "gpt-4o"
        static let apiVersion = "2024-02-15-preview"
        static let maxTokens = 500
        static let temperature = 0.7
    }

    // MARK: - App Settings

    struct App {
        /// Bundle identifier (must match Xcode project)
        static let bundleIdentifier = "com.replycopilot.app"

        /// App Group identifier for sharing data between app and extensions
        static let appGroupIdentifier = "group.com.replycopilot.shared"

        /// Keychain access group for secure storage
        static let keychainGroup = "com.replycopilot.keychain"

        /// App display name
        static let displayName = "ReplyCopilot"

        /// App version
        static let version = "1.0.0"

        /// Build number
        static let buildNumber = "1"
    }

    // MARK: - Feature Flags

    struct Features {
        /// Enable Firebase Analytics
        static let enableAnalytics = true

        /// Enable crash reporting
        static let enableCrashReporting = true

        /// Enable custom keyboard extension
        static let enableKeyboard = true

        /// Enable share extension
        static let enableShareExtension = true

        /// Enable beta features (only in debug)
        static let enableBetaFeatures = environment == .development

        /// Enable debug logging
        static let enableDebugLogging = environment != .production
    }

    // MARK: - Subscription Configuration

    struct Subscription {
        /// Free tier daily limit
        static let freeRepliesPerDay = 20

        /// Pro subscription price (displayed to users)
        static let proPrice = "$9.99"

        /// Pro subscription product ID (from App Store Connect)
        static let proProductID = "com.replycopilot.pro.monthly"

        /// Enterprise subscription product ID
        static let enterpriseProductID = "com.replycopilot.enterprise.monthly"

        /// App Store shared secret (from App Store Connect)
        /// TODO: Replace after setting up In-App Purchases
        static let appStoreSharedSecret = "REPLACE_WITH_APP_STORE_SHARED_SECRET"
    }

    // MARK: - Analytics Configuration

    struct Analytics {
        /// Mixpanel token (optional)
        static let mixpanelToken: String? = nil

        /// Amplitude API key (optional)
        static let amplitudeKey: String? = nil

        /// Enable event tracking
        static let enableEventTracking = true
    }

    // MARK: - Rate Limiting

    struct RateLimits {
        /// Maximum API requests per minute
        static let maxRequestsPerMinute = 30

        /// Maximum image size (in bytes) - 10MB
        static let maxImageSizeBytes = 10 * 1024 * 1024

        /// Maximum concurrent API requests
        static let maxConcurrentRequests = 3
    }

    // MARK: - Cache Configuration

    struct Cache {
        /// Maximum number of reply history items to keep
        static let maxHistoryItems = 100

        /// Days before cached items expire
        static let expirationDays = 30

        /// Enable disk caching
        static let enableDiskCache = true
    }

    // MARK: - UI Configuration

    struct UI {
        /// Animation duration (in seconds)
        static let animationDuration: TimeInterval = 0.3

        /// Haptic feedback enabled
        static let enableHaptics = true

        /// Dark mode support
        static let supportsDarkMode = true
    }

    // MARK: - Helper Methods

    /// Full API URL with endpoint
    static func apiURL(for endpoint: String) -> String {
        return "\(baseURL)\(endpoint)"
    }

    /// Full API URL with endpoint and function key
    static func authenticatedURL(for endpoint: String) -> String {
        return "\(baseURL)\(endpoint)?code=\(apiKey)"
    }

    /// Check if running in production
    static var isProduction: Bool {
        return environment == .production
    }

    /// Check if debug mode is enabled
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Config Extension for Debugging

#if DEBUG
extension Config {
    /// Print current configuration (debug only)
    static func printConfiguration() {
        print("""
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        🔧 ReplyCopilot Configuration
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Environment: \(environment.name)
        Base URL: \(baseURL)
        API Key: \(apiKey.prefix(10))...
        Bundle ID: \(App.bundleIdentifier)
        Version: \(App.version) (\(App.buildNumber))

        Features:
        - Analytics: \(Features.enableAnalytics ? "✅" : "❌")
        - Keyboard: \(Features.enableKeyboard ? "✅" : "❌")
        - Share Extension: \(Features.enableShareExtension ? "✅" : "❌")
        - Debug Logging: \(Features.enableDebugLogging ? "✅" : "❌")

        Subscription:
        - Free Limit: \(Subscription.freeRepliesPerDay) replies/day
        - Pro Price: \(Subscription.proPrice)/month

        Rate Limits:
        - Max Requests: \(RateLimits.maxRequestsPerMinute)/min
        - Max Image Size: \(RateLimits.maxImageSizeBytes / 1024 / 1024)MB
        - Concurrent: \(RateLimits.maxConcurrentRequests)
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        """)
    }
}
#endif
