import SwiftUI
import Firebase

// MARK: - App Entry Point
/**
 ReplyCopilotApp - Main App Entry Point

 LEARNING: SwiftUI App Lifecycle
 ================================
 In SwiftUI, the @main attribute marks this as the app's entry point.
 This replaces the old UIKit AppDelegate pattern (though we still use AppDelegate for Firebase).

 The App protocol defines the structure of your app with:
 - @main: Tells Swift this is where the app starts
 - var body: Defines the app's view hierarchy
 - Scene: A container for your app's UI (windows, tabs, etc.)

 WHY SwiftUI vs UIKit?
 - SwiftUI: Modern, declarative, less boilerplate
 - UIKit: Older, imperative, more control
 - This app uses SwiftUI with UIKit integration where needed
 */

@main
struct ReplyCopilotApp: App {

    // MARK: - Properties

    /**
     LEARNING: @UIApplicationDelegateAdaptor
     ========================================
     This property wrapper connects the old UIKit AppDelegate to SwiftUI.
     We need this for Firebase initialization and other iOS lifecycle events.

     WHY use AppDelegate in SwiftUI?
     - Some SDKs (Firebase, push notifications) require AppDelegate
     - Gives access to lifecycle methods not in SwiftUI
     - Bridge between old (UIKit) and new (SwiftUI) patterns
     */
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /**
     LEARNING: @StateObject
     =======================
     Creates and owns an ObservableObject that survives view updates.
     Use @StateObject for creating objects that the view owns.

     Difference from @ObservedObject:
     - @StateObject: View creates and owns it (persists across view updates)
     - @ObservedObject: View observes it but doesn't own it
     - @EnvironmentObject: Passed down from parent view

     Here we create ViewModels that manage app state:
     - AuthService: Handles Firebase and Azure AD authentication
     - StorageService: Manages UserDefaults, Keychain, App Groups
     - AnalyticsService: Tracks user behavior for Firebase Analytics
     */
    @StateObject private var authService = AuthService.shared
    @StateObject private var storageService = StorageService.shared
    @StateObject private var analyticsService = AnalyticsService.shared

    /**
     LEARNING: @AppStorage
     ======================
     Property wrapper for UserDefaults - perfect for simple preferences.
     Automatically syncs with UserDefaults and triggers view updates.

     WHY use @AppStorage?
     - Simple: No need to manually read/write UserDefaults
     - Reactive: View updates when value changes
     - Type-safe: Compile-time checking

     When to use what:
     - @AppStorage: Simple values (bool, int, string) in UserDefaults
     - Keychain: Sensitive data (passwords, tokens)
     - Firestore: User data that needs cloud sync
     - App Groups: Data shared between app and extensions
     */
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    // MARK: - Body

    /**
     LEARNING: Scene-Based Architecture
     ===================================
     The body defines your app's UI structure using Scenes.
     WindowGroup is the most common scene for iOS apps.

     Scene hierarchy:
     1. App (top level - ReplyCopilotApp)
     2. Scene (WindowGroup, DocumentGroup, etc.)
     3. View (Your SwiftUI views)

     WHY WindowGroup?
     - Automatically handles multiple windows on iPad
     - Manages state restoration
     - Handles scene lifecycle (foreground, background)
     */
    var body: some Scene {
        WindowGroup {
            /**
             LEARNING: Conditional View Based on State
             ==========================================
             SwiftUI makes it easy to show different views based on state.
             Here we show onboarding for new users, main content for returning users.

             This is the core of reactive UI:
             - State changes → View automatically updates
             - No manual view controller management needed
             */
            if hasCompletedOnboarding {
                // Main app for existing users
                ContentView()
                    .environmentObject(authService)
                    .environmentObject(storageService)
                    .environmentObject(analyticsService)
            } else {
                // Onboarding for new users
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .environmentObject(authService)
            }
        }
    }
}

// MARK: - App Delegate

/**
 LEARNING: UIApplicationDelegate
 ================================
 The traditional iOS app lifecycle manager.
 Still needed for certain iOS features that SwiftUI doesn't cover yet.

 WHEN to use AppDelegate:
 - Firebase initialization (requires early app lifecycle hook)
 - Push notification registration
 - URL scheme handling (deep links)
 - Background fetch setup
 - Third-party SDK initialization

 IMPORTANT: In SwiftUI, you connect AppDelegate using @UIApplicationDelegateAdaptor
 */
class AppDelegate: NSObject, UIApplicationDelegate {

    /**
     LEARNING: Application Lifecycle - didFinishLaunching
     ====================================================
     Called when the app has finished launching.
     Perfect place to initialize services that need to be ready before UI appears.

     ORDER of execution:
     1. AppDelegate.didFinishLaunching
     2. SwiftUI @main App init
     3. App.body computed
     4. Initial view appears
     */
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {

        // MARK: Firebase Setup

        /**
         LEARNING: Firebase Configuration
         =================================
         Firebase must be configured before any Firebase service is used.

         STEPS to set up Firebase:
         1. Create project at console.firebase.google.com
         2. Download GoogleService-Info.plist
         3. Add to Xcode project (drag into Xcode)
         4. Call FirebaseApp.configure()

         WHY Firebase?
         - Authentication: Easy user management
         - Firestore: Real-time database
         - Analytics: User behavior tracking
         - Crashlytics: Crash reporting
         - Remote Config: Feature flags

         NOTE: This must be called BEFORE any Firebase service (Auth, Firestore, etc.)
         */
        FirebaseApp.configure()

        // MARK: Logging

        /**
         LEARNING: Logging Best Practices
         =================================
         Always log important app lifecycle events for debugging.

         LEVELS of logging:
         - Debug: Development only, verbose
         - Info: Important events (user login, purchases)
         - Warning: Recoverable errors
         - Error: Serious problems

         In production, you'd use a logging framework like:
         - OSLog (Apple's system logger)
         - CocoaLumberjack
         - Firebase Crashlytics
         */
        Logger.info("🚀 ReplyCopilot app launched successfully")

        /**
         LEARNING: Analytics - App Launch Tracking
         ==========================================
         Track app launches to understand user engagement.

         METRICS to track:
         - App opens (daily active users)
         - Session duration
         - Feature usage
         - Error rates

         PRIVACY: Always anonymize user data and follow GDPR/CCPA
         */
        AnalyticsService.shared.logAppLaunch()

        return true
    }

    /**
     LEARNING: Application Lifecycle - Background/Foreground
     ========================================================
     These methods are called when the app moves between states.

     APP STATES:
     1. Not Running - App is terminated
     2. Inactive - App is transitioning (brief)
     3. Active - App is in foreground and receiving events
     4. Background - App is in background, running code
     5. Suspended - App is in background, not running code

     TRANSITIONS:
     - Launched → Inactive → Active (app opens)
     - Active → Inactive → Background (home button pressed)
     - Background → Inactive → Active (app returns)
     - Background → Suspended (iOS pauses app)
     - Suspended → Terminated (iOS kills app)
     */

    func applicationWillResignActive(_ application: UIApplication) {
        // App is about to move from active to inactive
        // GOOD FOR: Pausing ongoing tasks, disabling timers
        Logger.debug("App will resign active")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // App has moved to background
        // GOOD FOR: Saving data, releasing resources
        Logger.debug("App entered background")

        // Save any pending user data
        StorageService.shared.saveAllPendingData()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // App is about to enter foreground
        // GOOD FOR: Refreshing UI, resuming tasks
        Logger.debug("App will enter foreground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // App has become active
        // GOOD FOR: Restarting tasks, refreshing data
        Logger.debug("App became active")

        // Check for new features or updates
        checkForUpdates()
    }

    // MARK: - Helper Methods

    /**
     Check if app needs updates or has new features
     In production, this could check a remote config service
     */
    private func checkForUpdates() {
        // TODO: Implement update checking
        // Could use Firebase Remote Config for feature flags
        Logger.debug("Checking for updates...")
    }
}

// MARK: - Extensions

/**
 LEARNING: Swift Extensions
 ===========================
 Extensions add functionality to existing types.
 Great for organizing code and keeping view code clean.

 WHEN to use extensions:
 - Add computed properties
 - Add convenience methods
 - Conform to protocols
 - Organize large files

 CANNOT do in extensions:
 - Add stored properties
 - Override existing methods
 */

extension ReplyCopilotApp {
    /**
     Convenience method to reset app to onboarding state
     Useful for testing or when user signs out
     */
    func resetToOnboarding() {
        hasCompletedOnboarding = false
        authService.signOut()
        storageService.clearAllData()
        Logger.info("App reset to onboarding state")
    }
}

// MARK: - Documentation

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. SwiftUI App Structure
    - @main marks entry point
    - App protocol defines structure
    - Scene-based architecture (WindowGroup)

 2. State Management
    - @StateObject for owned ObservableObjects
    - @AppStorage for UserDefaults
    - @EnvironmentObject for passing down hierarchy

 3. AppDelegate Integration
    - @UIApplicationDelegateAdaptor bridges UIKit
    - Still needed for certain iOS features
    - Handles app lifecycle events

 4. Firebase Setup
    - Configure early in app lifecycle
    - Required before using any Firebase service
    - GoogleService-Info.plist must be in project

 5. App Lifecycle
    - Launch → Active → Background → Suspended
    - Save data in didEnterBackground
    - Refresh in didBecomeActive

 NEXT STEPS:
 ===========
 - Read ContentView.swift to see main app UI
 - Read OnboardingView.swift for first-run experience
 - Read AuthService.swift for authentication logic
 - Read StorageService.swift for data persistence

 RESOURCES:
 ==========
 - SwiftUI App lifecycle: developer.apple.com/documentation/swiftui/app
 - Firebase iOS setup: firebase.google.com/docs/ios/setup
 - App lifecycle guide: developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle
 */
