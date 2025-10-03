import Foundation
import FirebaseAnalytics
import FirebaseCore

/**
 AnalyticsService - Event Tracking & Metrics

 LEARNING: Analytics in iOS
 ===========================
 Analytics helps you understand:
 - How users use your app
 - Which features are popular
 - Where users get stuck
 - Conversion funnels
 - User retention
 - App performance

 Firebase Analytics provides:
 - Automatic events (app_open, screen_view)
 - Custom events
 - User properties
 - Audience segmentation
 - Free & unlimited
 - Integrates with other Firebase services

 PRIVACY:
 - No personal information
 - Aggregate data only
 - User can opt-out
 - GDPR compliant
 */

@MainActor
class AnalyticsService: ObservableObject {

    // MARK: - Singleton

    static let shared = AnalyticsService()

    // MARK: - Properties

    /// Whether analytics is enabled
    @Published var isEnabled: Bool {
        didSet {
            Analytics.setAnalyticsCollectionEnabled(isEnabled)
            UserDefaults.standard.set(isEnabled, forKey: "analyticsEnabled")
        }
    }

    /// Debug mode (verbose logging)
    private let debugMode: Bool

    // MARK: - Initialization

    private init() {
        // Check user preference
        self.isEnabled = UserDefaults.standard.bool(forKey: "analyticsEnabled")

        // Enable debug mode in debug builds
        #if DEBUG
        self.debugMode = true
        #else
        self.debugMode = false
        #endif

        // Initialize Firebase if needed
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }

        // Set analytics collection state
        Analytics.setAnalyticsCollectionEnabled(isEnabled)

        print("📊 Analytics initialized (enabled: \(isEnabled))")
    }

    // MARK: - Core Events

    /**
     LEARNING: Firebase Analytics Events
     ====================================
     Use predefined events when possible (better reporting)
     Custom events for app-specific actions
     Event names: lowercase_with_underscores
     Max 40 characters
     */

    /// Track app launch
    func trackAppLaunch() {
        logEvent("app_launch", parameters: [
            "app_version": Config.appVersion,
            "ios_version": UIDevice.current.systemVersion
        ])
    }

    /// Track screen view
    func trackScreenView(_ screenName: String, screenClass: String? = nil) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass ?? screenName
        ])

        if debugMode {
            print("📱 Screen: \(screenName)")
        }
    }

    /// Track button tap
    func trackButtonTap(_ buttonName: String, screen: String? = nil) {
        var parameters: [String: Any] = ["button_name": buttonName]
        if let screen = screen {
            parameters["screen"] = screen
        }
        logEvent("button_tap", parameters: parameters)
    }

    // MARK: - User Journey Events

    /**
     LEARNING: User Journey Tracking
     ================================
     Track key steps in user flow:
     - Onboarding
     - Feature discovery
     - Conversion points
     - Completion
     */

    /// Track onboarding started
    func trackOnboardingStarted() {
        logEvent("onboarding_started")
    }

    /// Track onboarding completed
    func trackOnboardingCompleted() {
        logEvent("onboarding_completed")
    }

    /// Track onboarding step
    func trackOnboardingStep(_ step: Int, title: String) {
        logEvent("onboarding_step", parameters: [
            "step": step,
            "title": title
        ])
    }

    /// Track sign up
    func trackSignUp(method: String) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    /// Track login
    func trackLogin(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    // MARK: - Feature Usage Events

    /**
     LEARNING: Feature Tracking
     ==========================
     Track when users use key features
     Helps prioritize development
     Identifies unused features
     */

    /// Track reply generation
    func trackReplyGeneration(
        platform: Platform,
        tone: Tone,
        success: Bool,
        responseTime: TimeInterval? = nil
    ) {
        var parameters: [String: Any] = [
            "platform": platform.rawValue,
            "tone": tone.rawValue,
            "success": success
        ]

        if let responseTime = responseTime {
            parameters["response_time"] = responseTime
        }

        logEvent("reply_generated", parameters: parameters)
    }

    /// Track reply copied
    func trackReplyCopied(tone: Tone, platform: Platform) {
        logEvent("reply_copied", parameters: [
            "tone": tone.rawValue,
            "platform": platform.rawValue
        ])
    }

    /// Track reply edited
    func trackReplyEdited(tone: Tone, platform: Platform) {
        logEvent("reply_edited", parameters: [
            "tone": tone.rawValue,
            "platform": platform.rawValue
        ])
    }

    /// Track satisfaction rating
    func trackSatisfactionRating(rating: Int, tone: Tone, platform: Platform) {
        logEvent("satisfaction_rating", parameters: [
            "rating": rating,
            "tone": tone.rawValue,
            "platform": platform.rawValue
        ])
    }

    /// Track share extension used
    func trackShareExtensionUsed(platform: Platform?) {
        var parameters: [String: Any] = [:]
        if let platform = platform {
            parameters["platform"] = platform.rawValue
        }
        logEvent("share_extension_used", parameters: parameters)
    }

    /// Track keyboard extension used
    func trackKeyboardExtensionUsed() {
        logEvent("keyboard_extension_used")
    }

    // MARK: - Subscription Events

    /**
     LEARNING: Revenue Tracking
     ==========================
     Track subscription lifecycle:
     - Initiated
     - Completed
     - Cancelled
     - Renewed

     Firebase automatically tracks in-app purchases
     But we log custom events for funnel analysis
     */

    /// Track subscription screen viewed
    func trackSubscriptionScreenViewed(source: String) {
        logEvent("subscription_screen_viewed", parameters: [
            "source": source
        ])
    }

    /// Track subscription purchase started
    func trackSubscriptionPurchaseStarted(tier: SubscriptionTier) {
        logEvent("subscription_purchase_started", parameters: [
            "tier": tier.rawValue
        ])
    }

    /// Track subscription purchase completed
    func trackSubscriptionPurchaseCompleted(tier: SubscriptionTier, price: Double) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterValue: price,
            AnalyticsParameterCurrency: "USD",
            "tier": tier.rawValue
        ])
    }

    /// Track subscription cancelled
    func trackSubscriptionCancelled(tier: SubscriptionTier, reason: String?) {
        var parameters: [String: Any] = ["tier": tier.rawValue]
        if let reason = reason {
            parameters["reason"] = reason
        }
        logEvent("subscription_cancelled", parameters: parameters)
    }

    // MARK: - Error Events

    /**
     LEARNING: Error Tracking
     ========================
     Track errors to identify issues
     Don't track expected errors
     Include context for debugging
     */

    /// Track API error
    func trackAPIError(_ error: APIError, endpoint: String? = nil) {
        var parameters: [String: Any] = [
            "error_type": String(describing: error)
        ]

        if let endpoint = endpoint {
            parameters["endpoint"] = endpoint
        }

        if let statusCode = error.statusCode {
            parameters["status_code"] = statusCode
        }

        logEvent("api_error", parameters: parameters)
    }

    /// Track auth error
    func trackAuthError(_ error: AuthError) {
        logEvent("auth_error", parameters: [
            "error_type": String(describing: error)
        ])
    }

    /// Track general error
    func trackError(
        _ error: Error,
        context: String? = nil,
        fatal: Bool = false
    ) {
        var parameters: [String: Any] = [
            "error": String(describing: error),
            "fatal": fatal
        ]

        if let context = context {
            parameters["context"] = context
        }

        logEvent("error", parameters: parameters)
    }

    // MARK: - Performance Events

    /**
     LEARNING: Performance Tracking
     ==============================
     Track app performance metrics
     Identify slow operations
     Optimize user experience
     */

    /// Track image compression time
    func trackImageCompression(
        originalSize: Int,
        compressedSize: Int,
        duration: TimeInterval
    ) {
        logEvent("image_compression", parameters: [
            "original_size": originalSize,
            "compressed_size": compressedSize,
            "compression_ratio": Double(compressedSize) / Double(originalSize),
            "duration": duration
        ])
    }

    /// Track API request duration
    func trackAPIRequestDuration(endpoint: String, duration: TimeInterval) {
        logEvent("api_request_duration", parameters: [
            "endpoint": endpoint,
            "duration": duration
        ])
    }

    // MARK: - User Properties

    /**
     LEARNING: User Properties
     =========================
     Set attributes about the user
     Used for audience segmentation
     Persists across sessions
     Max 25 properties
     */

    /// Set user ID
    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)

        if let userId = userId {
            if debugMode {
                print("👤 User ID set: \(userId)")
            }
        }
    }

    /// Set user properties
    func setUserProperties(_ properties: [String: String]) {
        for (key, value) in properties {
            Analytics.setUserProperty(value, forName: key)
        }

        if debugMode {
            print("📝 User properties: \(properties)")
        }
    }

    /// Set subscription tier
    func setSubscriptionTier(_ tier: SubscriptionTier) {
        Analytics.setUserProperty(tier.rawValue, forName: "subscription_tier")
    }

    /// Set user engagement level
    func setEngagementLevel(_ level: EngagementLevel) {
        Analytics.setUserProperty(level.rawValue, forName: "engagement_level")
    }

    /// Set preferred tone
    func setPreferredTone(_ tone: Tone) {
        Analytics.setUserProperty(tone.rawValue, forName: "preferred_tone")
    }

    /// Set most used platform
    func setMostUsedPlatform(_ platform: Platform) {
        Analytics.setUserProperty(platform.rawValue, forName: "most_used_platform")
    }

    // MARK: - Helper Methods

    /**
     LEARNING: Event Logging
     =======================
     Centralized logging function
     Adds debug output
     Validates parameters
     */

    private func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }

        Analytics.logEvent(name, parameters: parameters)

        if debugMode {
            if let parameters = parameters {
                print("📊 Event: \(name) - \(parameters)")
            } else {
                print("📊 Event: \(name)")
            }
        }
    }

    // MARK: - Opt In/Out

    /**
     LEARNING: Privacy Controls
     ==========================
     Give users control over analytics
     Required by GDPR/CCPA
     Respect user privacy
     */

    /// Enable analytics
    func enableAnalytics() {
        isEnabled = true
        logEvent("analytics_enabled")
    }

    /// Disable analytics
    func disableAnalytics() {
        logEvent("analytics_disabled")
        isEnabled = false
    }

    /// Reset analytics data
    func resetAnalyticsData() {
        Analytics.resetAnalyticsData()
        print("🔄 Analytics data reset")
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. Firebase Analytics
    - Free & unlimited
    - Automatic events
    - Custom events
    - User properties
    - Audience segmentation

 2. Event Tracking
    - Use predefined events
    - Custom events for app-specific
    - Include context in parameters
    - Track user journey

 3. User Properties
    - Set attributes about user
    - Used for segmentation
    - Persists across sessions
    - Max 25 properties

 4. Privacy
    - User opt-in/opt-out
    - No personal information
    - Aggregate data only
    - GDPR compliant

 5. Performance
    - Track slow operations
    - Measure API response times
    - Identify bottlenecks

 6. Error Tracking
    - Track unexpected errors
    - Include context
    - Don't track expected errors
    - Help debugging

 FIREBASE EVENTS REFERENCE:
 ==========================
 Predefined events (use when possible):
 - screen_view (automatic)
 - app_open (automatic)
 - first_open (automatic)
 - sign_up
 - login
 - purchase
 - search
 - share
 - select_content
 - add_to_cart
 - begin_checkout

 Custom events:
 - reply_generated
 - reply_copied
 - reply_edited
 - satisfaction_rating
 - share_extension_used
 - keyboard_extension_used
 - subscription_screen_viewed

 USAGE EXAMPLE:
 ==============
 ```swift
 let analytics = AnalyticsService.shared

 // Track app launch
 analytics.trackAppLaunch()

 // Track screen view
 analytics.trackScreenView("Home")

 // Track button tap
 analytics.trackButtonTap("generate_reply", screen: "Home")

 // Track feature usage
 analytics.trackReplyGeneration(
     platform: .whatsapp,
     tone: .friendly,
     success: true,
     responseTime: 1.2
 )

 // Track copy
 analytics.trackReplyCopied(tone: .friendly, platform: .whatsapp)

 // Track satisfaction
 analytics.trackSatisfactionRating(rating: 5, tone: .friendly, platform: .whatsapp)

 // Set user properties
 analytics.setUserId("user123")
 analytics.setSubscriptionTier(.pro)
 analytics.setEngagementLevel(.powerUser)

 // Track errors
 analytics.trackAPIError(error, endpoint: "/api/generateReplies")

 // Privacy controls
 analytics.enableAnalytics()
 analytics.disableAnalytics()
 ```

 SWIFTUI INTEGRATION:
 ===================
 ```swift
 struct ContentView: View {
     @StateObject private var analytics = AnalyticsService.shared

     var body: some View {
         NavigationView {
             HomeView()
                 .onAppear {
                     analytics.trackScreenView("Home")
                 }
         }
     }
 }

 struct SettingsView: View {
     @StateObject private var analytics = AnalyticsService.shared

     var body: some View {
         Form {
             Section {
                 Toggle("Analytics", isOn: $analytics.isEnabled)
                     .onChange(of: analytics.isEnabled) { enabled in
                         if enabled {
                             analytics.enableAnalytics()
                         } else {
                             analytics.disableAnalytics()
                         }
                     }
             }
         }
     }
 }
 ```

 FUNNEL ANALYSIS:
 ================
 Track user flow through features:

 ```swift
 // Onboarding funnel
 analytics.trackOnboardingStarted()
 analytics.trackOnboardingStep(1, title: "Welcome")
 analytics.trackOnboardingStep(2, title: "Permissions")
 analytics.trackOnboardingStep(3, title: "Setup")
 analytics.trackOnboardingCompleted()

 // Subscription funnel
 analytics.trackSubscriptionScreenViewed(source: "settings")
 analytics.trackSubscriptionPurchaseStarted(tier: .pro)
 analytics.trackSubscriptionPurchaseCompleted(tier: .pro, price: 9.99)

 // Reply generation funnel
 analytics.trackScreenView("Home")
 analytics.trackShareExtensionUsed(platform: .whatsapp)
 analytics.trackReplyGeneration(platform: .whatsapp, tone: .friendly, success: true)
 analytics.trackReplyCopied(tone: .friendly, platform: .whatsapp)
 analytics.trackSatisfactionRating(rating: 5, tone: .friendly, platform: .whatsapp)
 ```

 FIREBASE CONSOLE:
 =================
 View analytics in Firebase Console:
 1. Go to firebase.google.com
 2. Select your project
 3. Click "Analytics" in left menu
 4. View dashboards:
    - Overview
    - Events
    - Conversions
    - Audiences
    - User Properties
    - Latest Release
    - Retention
    - DebugView (real-time)

 TESTING:
 ========
 Enable debug mode:
 1. Edit scheme in Xcode
 2. Add argument: -FIRAnalyticsDebugEnabled
 3. Run app
 4. Go to Firebase Console > DebugView
 5. See real-time events

 NEXT STEPS:
 ===========
 - Configure Firebase project
 - Add analytics to all views
 - Set up conversion events
 - Create audiences
 - Integrate with Google Analytics 4
 - Add A/B testing with Firebase Remote Config
 */
