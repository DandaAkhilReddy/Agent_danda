import SwiftUI

/**
 ContentView - Main App Screen

 LEARNING: Navigation in SwiftUI
 ================================
 Two main approaches:
 1. TabView - Bottom tabs (iOS style)
 2. NavigationView - Hierarchical navigation

 We use TabView for main sections:
 - Home (recent suggestions)
 - History (all past replies)
 - Settings (preferences)
 */

struct ContentView: View {

    // MARK: - Properties

    /**
     LEARNING: EnvironmentObject
     ============================
     Shared across view hierarchy
     Injected at app level
     Accessible to all child views
     No need to pass through each level
     */

    @EnvironmentObject var authService: AuthService

    /// Currently selected tab
    @State private var selectedTab = 0

    /// Show settings sheet
    @State private var showingSettings = false

    /// Analytics service
    @StateObject private var analytics = AnalyticsService.shared

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // History Tab
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .onChange(of: selectedTab) { newTab in
            trackTabSwitch(newTab)
        }
    }

    // MARK: - Actions

    private func trackTabSwitch(_ tab: Int) {
        let tabName = switch tab {
        case 0: "Home"
        case 1: "History"
        case 2: "Settings"
        default: "Unknown"
        }
        analytics.trackScreenView(tabName)
    }
}

// MARK: - Home View

/**
 HomeView - Main Dashboard
 Shows recent suggestions and quick actions
 */

struct HomeView: View {

    // MARK: - Properties

    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var authService: AuthService

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome header
                    welcomeHeader

                    // Usage stats card
                    usageStatsCard

                    // Quick action buttons
                    quickActions

                    // Recent suggestions
                    recentSuggestionsSection

                    Spacer(minLength: 32)
                }
                .padding()
            }
            .navigationTitle("ReplyCopilot")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    profileButton
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Subviews

    private var welcomeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hello, \(authService.currentUser?.displayName ?? "there")! 👋")
                .font(.title2)
                .fontWeight(.bold)

            Text("Ready to generate some awesome replies?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var usageStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Usage")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(viewModel.usageToday)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)

                        Text("/ \(viewModel.dailyLimit)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: viewModel.usagePercentage)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(viewModel.usagePercentage * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }

            if viewModel.isNearLimit {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("You're running low on replies today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Upgrade") {
                        // Navigate to subscription
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Use")
                .font(.headline)

            HStack(spacing: 12) {
                QuickActionCard(
                    icon: "camera.viewfinder",
                    title: "Screenshot",
                    description: "Take a screenshot of any chat",
                    color: .blue
                )

                QuickActionCard(
                    icon: "square.and.arrow.up",
                    title: "Share",
                    description: "Share to ReplyCopilot",
                    color: .green
                )

                QuickActionCard(
                    icon: "doc.on.clipboard",
                    title: "Copy",
                    description: "Copy & paste reply",
                    color: .purple
                )
            }
        }
    }

    private var recentSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Suggestions")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    HistoryView()
                }
                .font(.subheadline)
            }

            if viewModel.recentSuggestions.isEmpty {
                emptyState
            } else {
                ForEach(viewModel.recentSuggestions) { suggestion in
                    SuggestionCard(suggestion: suggestion)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.badge")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
                .padding()

            Text("No suggestions yet")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Take a screenshot and share it to ReplyCopilot to get started!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var profileButton: some View {
        NavigationLink {
            SettingsView()
        } label: {
            if let photoURL = authService.currentUser?.photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Text(authService.currentUser?.initials ?? "?")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(authService.currentUser?.initials ?? "?")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
            }
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color.gradient)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)

            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Suggestion Card

struct SuggestionCard: View {
    let suggestion: ReplySuggestion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Platform badge
                Label(suggestion.platform.displayName, systemImage: suggestion.platform.iconName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: suggestion.platform.color)?.opacity(0.2))
                    .foregroundColor(Color(hex: suggestion.platform.color))
                    .clipShape(Capsule())

                Spacer()

                // Tone badge
                Text("\(suggestion.tone.emoji) \(suggestion.tone.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(suggestion.text)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(3)

            HStack {
                Text(suggestion.timeAgo)
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    UIPasteboard.general.string = suggestion.text
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Home ViewModel

/**
 LEARNING: MVVM Pattern
 ======================
 Model-View-ViewModel architecture
 - Model: Data (ReplySuggestion)
 - View: UI (HomeView)
 - ViewModel: Business logic (HomeViewModel)

 Benefits:
 - Separation of concerns
 - Testable business logic
 - Reusable code
 */

@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var recentSuggestions: [ReplySuggestion] = []
    @Published var usageToday: Int = 0
    @Published var dailyLimit: Int = 20
    @Published var isLoading = false

    // MARK: - Computed Properties

    var usagePercentage: Double {
        guard dailyLimit > 0 else { return 0 }
        return Double(usageToday) / Double(dailyLimit)
    }

    var isNearLimit: Bool {
        usagePercentage >= 0.8
    }

    // MARK: - Services

    private let storage = StorageService.shared
    private let analytics = AnalyticsService.shared

    // MARK: - Methods

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Load recent suggestions
        recentSuggestions = Array(storage.loadHistory().prefix(5))

        // Load usage from preferences
        if let prefs = storage.loadPreferences() {
            usageToday = prefs.dailyUsageCount
            dailyLimit = prefs.subscriptionTier.dailyLimit ?? Int.max
        }

        analytics.trackScreenView("Home")
    }

    func refresh() async {
        await loadData()
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0

        guard Scanner(string: hex).scanHexInt64(&int) else {
            return nil
        }

        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

// MARK: - Preview

#Preview("Content View") {
    ContentView()
        .environmentObject(AuthService.shared)
}

#Preview("Home View") {
    HomeView()
        .environmentObject(AuthService.shared)
}

#Preview("Empty State") {
    NavigationView {
        HomeView()
            .environmentObject(AuthService.shared)
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. TabView Navigation
    - Bottom tab bar
    - Multiple root views
    - Tag for identification
    - Badge support

 2. ScrollView
    - Scrollable content
    - VStack for vertical layout
    - refreshable modifier
    - Pull to refresh

 3. Cards & Layout
    - Rounded rectangles
    - Background colors
    - Padding and spacing
    - Shadows and elevation

 4. Progress Indicators
    - Circular progress
    - Trim for partial circle
    - Gradient strokes
    - Rotation effect

 5. Async Data Loading
    - .task modifier
    - async/await in SwiftUI
    - @MainActor for UI updates
    - Loading states

 6. MVVM Architecture
    - Separate business logic
    - ObservableObject ViewModel
    - @Published for reactive updates
    - Testable code

 7. Empty States
    - Show when no data
    - Helpful instructions
    - Call to action
    - Good UX

 8. Toolbar
    - Navigation bar items
    - Profile button
    - Action buttons
    - ToolbarItem placement

 9. NavigationLink
    - Programmatic navigation
    - Lazy loading
    - Back button automatic
    - Deep linking support

 10. Refresh Control
     - refreshable modifier
     - Pull to refresh
     - Async data fetch
     - Native iOS behavior

 USAGE EXAMPLE:
 ==============
 ```swift
 @main
 struct ReplyCopilotApp: App {
     @StateObject private var authService = AuthService.shared

     var body: some Scene {
         WindowGroup {
             ContentView()
                 .environmentObject(authService)
         }
     }
 }
 ```

 CUSTOMIZATION:
 ==============
 Easy to modify:
 - Add more tabs
 - Change tab icons
 - Reorder tabs
 - Custom tab bar
 - Badge counts

 ```swift
 TabView {
     HomeView()
         .tabItem {
             Label("Home", systemImage: "house.fill")
         }
         .badge(5) // Show badge

     // More tabs...
 }
 .accentColor(.blue) // Selected tab color
 ```

 NEXT STEPS:
 ===========
 - Add pull to refresh
 - Add search functionality
 - Add filters
 - Add sorting options
 - Add quick actions
 - Add widgets
 */
