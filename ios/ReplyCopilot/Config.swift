import Foundation

/**
 Configuration - Centralized App Configuration

 LEARNING: Configuration Management
 ==================================
 Centralizing configuration makes it easy to:
 - Switch between dev/staging/prod environments
 - Update API endpoints
 - Manage feature flags
 - Handle different build configurations

 PROFESSIONAL PATTERN:
 Use enums for type-safe configuration access
 No hardcoded strings throughout codebase
 */

enum Config {

    // MARK: - Environment

    /**
     LEARNING: Build Configuration Detection
     ========================================
     Swift provides DEBUG flag in debug builds
     Use #if DEBUG for conditional compilation
     */
    static var environment: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    enum Environment {
        case development
        case staging
        case production

        var name: String {
            switch self {
            case .development: return "Development"
            case .staging: return "Staging"
            case .production: return "Production"
            }
        }
    }

    // MARK: - API Configuration

    /**
     Azure Backend API Configuration
     Replace with your actual Azure Function URL after deployment
     */
    static var apiURL: String {
        switch environment {
        case .development:
            return "http://localhost:7071" // Local Azure Functions
        case .staging:
            return "https://replycopilot-api-staging.azurewebsites.net"
        case .production:
            return "https://replycopilot-api.azurewebsites.net"
        }
    }

    static let apiVersion = "v1"
    static let apiTimeout: TimeInterval = 30.0 // 30 seconds

    // Full API endpoint
    static var apiEndpoint: String {
        return "\(apiURL)/api/\(apiVersion)"
    }

    // MARK: - Azure AD Configuration

    /**
     Azure Active Directory for backend authentication
     Get these values from Azure Portal after AD app registration
     */
    static let azureClientId = "YOUR_AZURE_AD_CLIENT_ID" // TODO: Replace
    static let azureTenantId = "YOUR_AZURE_TENANT_ID"    // TODO: Replace
    static let azureRedirectUri = "msauth.com.replycopilot.app://auth"

    // MARK: - Firebase Configuration

    /**
     Firebase configuration
     GoogleService-Info.plist must be added to Xcode project
     */
    static let firebaseProjectId = "reddyfit-dcf41"

    // MARK: - App Configuration

    /// Bundle identifier (must match Xcode)
    static let bundleIdentifier = "com.replycopilot.app"

    /// App Groups identifier for sharing data between extensions
    /// IMPORTANT: Must match in Xcode Signing & Capabilities
    static let appGroupIdentifier = "group.com.replycopilot.shared"

    /// Keychain access group for sharing tokens
    static let keychainAccessGroup = "com.replycopilot.keychain"

    /// App version
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    /// Build number
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Feature Flags

    /**
     LEARNING: Feature Flags
     =======================
     Control feature rollout without app updates
     A/B testing
     Gradual rollout
     Emergency kill switch

     In production, fetch from Firebase Remote Config
     */
    static var enableKeyboard: Bool {
        switch environment {
        case .development:
            return true
        case .staging:
            return true
        case .production:
            return true // Can disable if issues arise
        }
    }

    static var enableAnalytics: Bool {
        switch environment {
        case .development:
            return false // Don't pollute analytics in dev
        case .staging:
            return true
        case .production:
            return true
        }
    }

    static var enableCrashReporting: Bool {
        return environment == .production
    }

    // MARK: - Limits & Constraints

    /// Free tier daily limit
    static let freeTierDailyLimit = 20

    /// Maximum screenshot size (MB)
    static let maxScreenshotSizeMB = 10

    /// Maximum suggestions to request
    static let maxSuggestions = 5

    /// Minimum suggestions to display
    static let minSuggestions = 3

    // MARK: - Subscription

    /**
     In-App Purchase Product IDs
     Must match App Store Connect configuration
     */
    static let proMonthlyProductId = "com.replycopilot.pro.monthly"
    static let proYearlyProductId = "com.replycopilot.pro.yearly"
    static let familyMonthlyProductId = "com.replycopilot.family.monthly"

    // MARK: - URLs

    static let websiteURL = URL(string: "https://replycopilot.com")!
    static let privacyPolicyURL = URL(string: "https://replycopilot.com/privacy")!
    static let termsOfServiceURL = URL(string: "https://replycopilot.com/terms")!
    static let supportEmail = "support@replycopilot.com"

    // MARK: - App Store

    static let appStoreId = "YOUR_APP_ID" // TODO: Replace after App Store Connect
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id\(appStoreId)")

    // MARK: - Debugging

    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    static var verboseLogging: Bool {
        return isDebug
    }
}

// MARK: - Helper Extensions

extension Config {
    /**
     Print configuration on app launch (debug only)
     Useful for verifying environment settings
     */
    static func printConfiguration() {
        guard isDebug else { return }

        print("=== ReplyCopilot Configuration ===")
        print("Environment: \(environment.name)")
        print("API URL: \(apiURL)")
        print("Bundle ID: \(bundleIdentifier)")
        print("App Group: \(appGroupIdentifier)")
        print("Features:")
        print("  - Keyboard: \(enableKeyboard)")
        print("  - Analytics: \(enableAnalytics)")
        print("  - Crash Reporting: \(enableCrashReporting)")
        print("==================================")
    }
}

/**
 KEY CONCEPTS:
 =============

 1. Centralized Configuration
    - Single source of truth
    - Easy to update
    - Type-safe access

 2. Environment Switching
    - Dev/Staging/Prod
    - Conditional compilation (#if DEBUG)
    - Build-time decisions

 3. Feature Flags
    - Control features without app updates
    - A/B testing
    - Gradual rollout

 4. Constants
    - No magic strings
    - Easy to find and update
    - Documented in one place

 NEXT STEPS:
 ===========
 After Azure deployment, update:
 - apiURL (production)
 - azureClientId
 - azureTenantId
 - appStoreId (after App Store Connect)
 */
