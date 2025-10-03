import SwiftUI

/**
 SettingsView - User Preferences & Account Management

 LEARNING: Form in SwiftUI
 ==========================
 Form is a container for grouped settings
 - Automatic styling for iOS
 - Sections with headers/footers
 - Built-in controls (Toggle, Picker, etc.)
 - Adaptive layout
 */

struct SettingsView: View {

    // MARK: - Properties

    @StateObject private var viewModel = SettingsViewModel()
    @EnvironmentObject var authService: AuthService

    /// Show logout confirmation
    @State private var showingLogoutAlert = false

    /// Show delete account confirmation
    @State private var showingDeleteAlert = false

    /// Show subscription sheet
    @State private var showingSubscription = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // Profile Section
                profileSection

                // Subscription Section
                subscriptionSection

                // Preferences Section
                preferencesSection

                // Platform Preferences Section
                platformPreferencesSection

                // Privacy Section
                privacySection

                // Notifications Section
                notificationsSection

                // Support Section
                supportSection

                // Account Section
                accountSection

                // App Info Section
                appInfoSection
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all data. This action cannot be undone.")
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Sections

    /**
     LEARNING: Form Sections
     =======================
     Section groups related settings
     header: Title at top
     footer: Description at bottom
     */

    private var profileSection: some View {
        Section {
            HStack(spacing: 16) {
                // Profile photo
                if let photoURL = authService.currentUser?.photoURL {
                    AsyncImage(url: photoURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.gradient)
                            .overlay {
                                Text(authService.currentUser?.initials ?? "?")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 60, height: 60)
                        .overlay {
                            Text(authService.currentUser?.initials ?? "?")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(authService.currentUser?.displayName ?? "User")
                        .font(.headline)

                    Text(authService.currentUser?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let user = authService.currentUser, !user.isEmailVerified {
                        Button("Verify Email") {
                            Task {
                                try? await authService.sendEmailVerification()
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var subscriptionSection: some View {
        Section {
            Button {
                showingSubscription = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.subscriptionTier.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(viewModel.subscriptionTier.price)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if viewModel.subscriptionTier == .free {
                        Text("Upgrade")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue.gradient)
                            .clipShape(Capsule())
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }

            // Usage stats
            HStack {
                Text("Daily Usage")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.usageToday) / \(viewModel.dailyLimit)")
                    .fontWeight(.medium)
            }
        } header: {
            Text("Subscription")
        } footer: {
            if viewModel.subscriptionTier == .free {
                Text("Upgrade to Pro for unlimited replies, priority support, and advanced features.")
            }
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            // Default tone picker
            Picker("Default Tone", selection: $viewModel.defaultTone) {
                ForEach(Tone.allCases) { tone in
                    HStack {
                        Text(tone.emoji)
                        Text(tone.displayName)
                    }
                    .tag(tone)
                }
            }

            // Haptic feedback toggle
            Toggle("Haptic Feedback", isOn: $viewModel.hapticFeedbackEnabled)

            // Theme picker
            Picker("Appearance", selection: $viewModel.selectedTheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
        }
    }

    private var platformPreferencesSection: some View {
        Section {
            ForEach(Platform.allCases) { platform in
                HStack {
                    Image(systemName: platform.iconName)
                        .foregroundColor(Color(hex: platform.color))
                        .frame(width: 24)

                    Text(platform.displayName)

                    Spacer()

                    Picker("", selection: Binding(
                        get: { viewModel.platformTones[platform] ?? viewModel.defaultTone },
                        set: { viewModel.platformTones[platform] = $0 }
                    )) {
                        ForEach(Tone.allCases) { tone in
                            Text(tone.emoji).tag(tone)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        } header: {
            Text("Platform Preferences")
        } footer: {
            Text("Choose a preferred tone for each platform. Falls back to default tone if not set.")
        }
    }

    private var privacySection: some View {
        Section {
            Toggle("Analytics", isOn: $viewModel.analyticsEnabled)

            Toggle("Crash Reporting", isOn: $viewModel.crashReportingEnabled)

            Toggle("Personalized Suggestions", isOn: $viewModel.personalizedSuggestions)

            NavigationLink("Privacy Policy") {
                PrivacyPolicyView()
            }

            NavigationLink("Terms of Service") {
                TermsOfServiceView()
            }
        } header: {
            Text("Privacy & Data")
        } footer: {
            Text("We never store your screenshots. Analytics are anonymous and help us improve the app.")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Daily Limit Warning", isOn: $viewModel.dailyLimitWarning)

            Toggle("New Features", isOn: $viewModel.newFeaturesNotifications)

            Toggle("Weekly Digest", isOn: $viewModel.weeklyDigest)

            Toggle("Notification Sounds", isOn: $viewModel.soundEnabled)
        } header: {
            Text("Notifications")
        }
    }

    private var supportSection: some View {
        Section("Support") {
            NavigationLink("Help Center") {
                HelpCenterView()
            }

            Link("Contact Support", destination: URL(string: "mailto:support@replycopilot.app")!)

            Button("Rate on App Store") {
                // Open App Store rating
                if let url = URL(string: "itms-apps://itunes.apple.com/app/idXXXXXXXXXX?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }

            NavigationLink("What's New") {
                WhatsNewView()
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            Button("Change Password") {
                // Navigate to change password
            }

            Button("Sign Out") {
                showingLogoutAlert = true
            }
            .foregroundColor(.red)

            Button("Delete Account") {
                showingDeleteAlert = true
            }
            .foregroundColor(.red)
        }
    }

    private var appInfoSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(viewModel.buildNumber)
                    .foregroundColor(.secondary)
            }

            Button("Clear Cache") {
                viewModel.clearCache()
            }
        } footer: {
            Text("ReplyCopilot © 2025\nMade with ❤️ for better conversations")
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }
}

// MARK: - Settings ViewModel

@MainActor
class SettingsViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var defaultTone: Tone = .friendly
    @Published var platformTones: [Platform: Tone] = [:]
    @Published var subscriptionTier: SubscriptionTier = .free
    @Published var usageToday: Int = 0
    @Published var dailyLimit: String = "20"

    @Published var hapticFeedbackEnabled = true
    @Published var selectedTheme = "system"

    @Published var analyticsEnabled = true
    @Published var crashReportingEnabled = true
    @Published var personalizedSuggestions = true

    @Published var dailyLimitWarning = true
    @Published var newFeaturesNotifications = true
    @Published var weeklyDigest = false
    @Published var soundEnabled = true

    // MARK: - Services

    private let storage = StorageService.shared
    private let authService = AuthService.shared
    private let analytics = AnalyticsService.shared

    // MARK: - Computed Properties

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Methods

    func loadData() async {
        // Load preferences
        if let prefs = storage.loadPreferences() {
            defaultTone = prefs.defaultTone
            platformTones = prefs.platformPreferences
            subscriptionTier = prefs.subscriptionTier
            usageToday = prefs.dailyUsageCount

            if let limit = prefs.subscriptionTier.dailyLimit {
                dailyLimit = "\(limit)"
            } else {
                dailyLimit = "∞"
            }

            // Notification settings
            dailyLimitWarning = prefs.notificationSettings.dailyLimitWarning
            newFeaturesNotifications = prefs.notificationSettings.newFeatures
            weeklyDigest = prefs.notificationSettings.weeklyDigest
            soundEnabled = prefs.notificationSettings.soundEnabled

            // Privacy settings
            analyticsEnabled = prefs.privacySettings.analyticsEnabled
            crashReportingEnabled = prefs.privacySettings.crashReportingEnabled
            personalizedSuggestions = prefs.privacySettings.personalizedSuggestions
        }

        // Load app settings
        hapticFeedbackEnabled = storage.hapticFeedbackEnabled
        selectedTheme = storage.selectedTheme

        analytics.trackScreenView("Settings")
    }

    func savePreferences() {
        guard var prefs = storage.loadPreferences() else { return }

        prefs.defaultTone = defaultTone
        prefs.platformPreferences = platformTones

        prefs.notificationSettings.dailyLimitWarning = dailyLimitWarning
        prefs.notificationSettings.newFeatures = newFeaturesNotifications
        prefs.notificationSettings.weeklyDigest = weeklyDigest
        prefs.notificationSettings.soundEnabled = soundEnabled

        prefs.privacySettings.analyticsEnabled = analyticsEnabled
        prefs.privacySettings.crashReportingEnabled = crashReportingEnabled
        prefs.privacySettings.personalizedSuggestions = personalizedSuggestions

        try? storage.savePreferences(prefs)

        storage.hapticFeedbackEnabled = hapticFeedbackEnabled
        storage.selectedTheme = selectedTheme

        analytics.setPreferredTone(defaultTone)
    }

    func signOut() {
        do {
            try authService.signOut()
            analytics.trackButtonTap("sign_out", screen: "Settings")
        } catch {
            print("Sign out error: \(error)")
        }
    }

    func deleteAccount() async {
        do {
            try await authService.deleteAccount()
            analytics.trackButtonTap("delete_account", screen: "Settings")
        } catch {
            print("Delete account error: \(error)")
        }
    }

    func clearCache() {
        storage.clearCache()
        analytics.trackButtonTap("clear_cache", screen: "Settings")
    }
}

// MARK: - Placeholder Views

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("🚀")
                    .font(.system(size: 80))

                Text("Upgrade to Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Unlock unlimited replies and advanced features")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "infinity", text: "Unlimited replies per day")
                    FeatureRow(icon: "star.fill", text: "Priority support")
                    FeatureRow(icon: "chart.bar.fill", text: "Advanced analytics")
                    FeatureRow(icon: "paintbrush.fill", text: "Custom tones (coming soon)")
                }
                .padding()

                Spacer()

                Button {
                    // Handle purchase
                } label: {
                    Text("Subscribe for $9.99/month")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("Cancel anytime. 7-day free trial.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy")
                .font(.title)
                .padding()
            Text("Your privacy policy content here...")
                .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service")
                .font(.title)
                .padding()
            Text("Your terms of service content here...")
                .padding()
        }
        .navigationTitle("Terms of Service")
    }
}

struct HelpCenterView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                NavigationLink("How to use ReplyCopilot") {
                    Text("Tutorial content...")
                }
                NavigationLink("Understanding tones") {
                    Text("Tone explanation...")
                }
            }
        }
        .navigationTitle("Help Center")
    }
}

struct WhatsNewView: View {
    var body: some View {
        List {
            Section("Version 1.0.0") {
                Text("🎉 Initial release")
                Text("🤖 GPT-4o Vision integration")
                Text("📱 6 platform adapters")
                Text("🎨 4 tone styles")
            }
        }
        .navigationTitle("What's New")
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
        .environmentObject(AuthService.shared)
}

#Preview("Subscription") {
    SubscriptionView()
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. Form in SwiftUI
    - Grouped settings
    - Automatic styling
    - Sections with headers/footers
    - Adaptive layout

 2. Pickers
    - Segmented style
    - Menu style
    - Wheel style
    - Inline style

 3. Toggles
    - Two-state controls
    - Binding to @Published
    - Automatic updates

 4. NavigationLink
    - Push to detail view
    - Lazy loading
    - Back button automatic

 5. Sheets
    - Modal presentation
    - Dismiss environment value
    - Full screen option

 6. Alerts
    - Confirmation dialogs
    - Destructive actions
    - Multiple buttons

 7. Two-Way Bindings
    - $ prefix for Binding
    - Custom Binding with get/set
    - Computed bindings

 8. ViewModel Pattern
    - Business logic separate
    - @Published for reactivity
    - Save/load data

 NEXT STEPS:
 ===========
 - Add in-app purchases
 - Add biometric auth
 - Add export data
 - Add import settings
 - Add custom themes
 */
