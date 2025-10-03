import SwiftUI

/**
 OnboardingView - First-Run Experience

 LEARNING: SwiftUI Basics
 ========================
 SwiftUI is Apple's modern UI framework:
 - Declarative syntax (describe what, not how)
 - Automatic updates (reactive)
 - Live previews in Xcode
 - Cross-platform (iOS, macOS, watchOS, tvOS)

 LEARNING: View Protocol
 ========================
 All SwiftUI views conform to View protocol
 Must implement 'body' property
 body returns 'some View' (opaque return type)
 */

struct OnboardingView: View {

    // MARK: - Properties

    /**
     LEARNING: Property Wrappers
     ===========================
     @State: Local mutable state
     @Binding: Two-way connection to parent
     @StateObject: Observable object (owns)
     @ObservedObject: Observable object (doesn't own)
     @EnvironmentObject: Shared across views
     @AppStorage: UserDefaults binding
     */

    /// Current page index (0-2)
    @State private var currentPage = 0

    /// Whether to show permission alert
    @State private var showingPermissionAlert = false

    /// Binding to parent's completion state
    @Binding var hasCompletedOnboarding: Bool

    /// Analytics service
    @StateObject private var analytics = AnalyticsService.shared

    // MARK: - Onboarding Pages

    /**
     LEARNING: Computed Properties
     =============================
     Calculate value when accessed
     No stored value
     Keeps code clean
     */

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                title: "AI-Powered Replies",
                subtitle: "Generate perfect responses instantly",
                description: "Take a screenshot of any chat, and our AI will suggest 3-5 contextual replies tailored to your style.",
                imageName: "message.badge.filled.fill",
                color: .blue,
                features: [
                    "🤖 Powered by GPT-4o Vision",
                    "⚡️ Instant suggestions",
                    "🎯 Context-aware replies"
                ]
            ),
            OnboardingPage(
                title: "Adapt to Any Platform",
                subtitle: "Perfect tone for every conversation",
                description: "WhatsApp, iMessage, Instagram, Outlook, Slack, Teams - we understand each platform's unique style.",
                imageName: "apps.iphone",
                color: .purple,
                features: [
                    "💼 Professional for work",
                    "😊 Friendly for friends",
                    "😂 Funny for fun chats"
                ]
            ),
            OnboardingPage(
                title: "Privacy First",
                subtitle: "Your data stays yours",
                description: "Screenshots are never stored. We process in memory and immediately discard them. Your privacy is our priority.",
                imageName: "lock.shield.fill",
                color: .green,
                features: [
                    "🔒 Zero data retention",
                    "🛡️ Encrypted communication",
                    "✅ GDPR compliant"
                ]
            )
        ]
    }

    // MARK: - Body

    /**
     LEARNING: View Body
     ===================
     'body' is the main view content
     Automatically called by SwiftUI
     Returns 'some View' (any View type)
     Recomputed when @State changes
     */

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            skipButton

            // Page content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    OnboardingPageView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Bottom buttons
            bottomButtons
        }
        .onAppear {
            analytics.trackOnboardingStarted()
        }
        .alert("Notifications", isPresented: $showingPermissionAlert) {
            Button("Allow") {
                requestNotifications()
            }
            Button("Not Now", role: .cancel) {
                completeOnboarding()
            }
        } message: {
            Text("Get notified when you reach your daily limit and when we add new features.")
        }
    }

    // MARK: - Subviews

    /**
     LEARNING: View Composition
     ==========================
     Break complex views into smaller pieces
     Each computed property returns a View
     Makes code readable and maintainable
     */

    /// Skip button in top right
    private var skipButton: some View {
        HStack {
            Spacer()
            Button("Skip") {
                analytics.trackButtonTap("skip_onboarding")
                completeOnboarding()
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
        }
    }

    /// Bottom navigation buttons
    private var bottomButtons: some View {
        HStack(spacing: 16) {
            // Back button (only show if not on first page)
            if currentPage > 0 {
                Button(action: previousPage) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 50, height: 50)
                        .background(Color.secondary.opacity(0.2))
                        .clipShape(Circle())
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Spacer()

            // Next/Get Started button
            Button(action: nextPage) {
                HStack {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(.headline)

                    if currentPage < pages.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: currentPage == pages.count - 1 ? .infinity : nil)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(pages[currentPage].color)
                .clipShape(Capsule())
            }
        }
        .padding()
        .padding(.bottom, 8)
    }

    // MARK: - Actions

    /**
     LEARNING: Functions in SwiftUI
     ==============================
     Define behavior separate from UI
     Called from button actions
     Can update @State properties
     */

    private func previousPage() {
        withAnimation(.spring()) {
            currentPage -= 1
        }
        analytics.trackOnboardingStep(currentPage, title: pages[currentPage].title)
    }

    private func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring()) {
                currentPage += 1
            }
            analytics.trackOnboardingStep(currentPage, title: pages[currentPage].title)
        } else {
            // Last page - show permission alert or complete
            showingPermissionAlert = true
        }
    }

    private func requestNotifications() {
        // TODO: Request notification permission
        // Will implement with UNUserNotificationCenter
        completeOnboarding()
    }

    private func completeOnboarding() {
        analytics.trackOnboardingCompleted()

        withAnimation(.spring()) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Page View

/**
 LEARNING: Custom View Components
 ================================
 Create reusable view components
 Extract into separate structs
 Keeps main view clean
 */

struct OnboardingPageView: View {

    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [page.color, page.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolRenderingMode(.hierarchical)
                .padding(.bottom, 16)

            // Title
            Text(page.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(page.subtitle)
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)

            // Features list
            VStack(alignment: .leading, spacing: 12) {
                ForEach(page.features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 8)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Page Model

/**
 LEARNING: Data Models for UI
 =============================
 Define data structures for views
 Keeps data separate from UI
 Easy to modify content
 */

struct OnboardingPage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
    let features: [String]
}

// MARK: - Preview

/**
 LEARNING: SwiftUI Previews
 ==========================
 Live preview in Xcode
 Multiple preview variants
 Test different states
 No need to run app!
 */

#Preview("Onboarding") {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}

#Preview("Page 1") {
    OnboardingPageView(
        page: OnboardingPage(
            title: "AI-Powered Replies",
            subtitle: "Generate perfect responses instantly",
            description: "Take a screenshot of any chat, and our AI will suggest 3-5 contextual replies.",
            imageName: "message.badge.filled.fill",
            color: .blue,
            features: [
                "🤖 Powered by GPT-4o Vision",
                "⚡️ Instant suggestions",
                "🎯 Context-aware replies"
            ]
        )
    )
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. SwiftUI Basics
    - Declarative syntax
    - View protocol
    - Body property
    - some View return type

 2. Property Wrappers
    - @State for local state
    - @Binding for parent connection
    - @StateObject for services
    - Automatic UI updates

 3. View Composition
    - Break into smaller views
    - Computed properties for subviews
    - Extract reusable components
    - Clean and maintainable

 4. SF Symbols
    - 5,000+ built-in icons
    - System fonts (scale automatically)
    - Symbol rendering modes
    - Colors and gradients

 5. Animations
    - withAnimation() wrapper
    - .spring() for natural motion
    - .transition() for enter/exit
    - Automatic interpolation

 6. TabView
    - Swipeable pages
    - Page indicators
    - Selection binding
    - Tag for identification

 7. Gradients
    - LinearGradient
    - RadialGradient
    - AngularGradient
    - Color stops

 8. Layout
    - VStack (vertical)
    - HStack (horizontal)
    - ZStack (depth)
    - Spacer for flexible space
    - Padding for margins

 9. Modifiers
    - Chain with dot syntax
    - Order matters!
    - Apply to any view
    - Build custom modifiers

 10. Previews
     - Live in Xcode
     - Multiple variants
     - Test different states
     - Fast iteration

 SWIFTUI LAYOUT SYSTEM:
 ======================
 Parent proposes size to child
 Child chooses its own size
 Parent positions child

 Stack behaviors:
 - VStack: Equal width, varied height
 - HStack: Varied width, equal height
 - ZStack: Size of largest child

 COMMON MODIFIERS:
 =================
 Layout:
 - .frame(width:height:)
 - .padding()
 - .offset(x:y:)
 - .position(x:y:)

 Appearance:
 - .foregroundColor()
 - .background()
 - .clipShape()
 - .shadow()

 Interaction:
 - .onTapGesture()
 - .gesture()
 - .disabled()

 Animation:
 - .animation()
 - .transition()
 - withAnimation {}

 USAGE EXAMPLE:
 ==============
 ```swift
 // In App struct
 @main
 struct ReplyCopilotApp: App {
     @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

     var body: some Scene {
         WindowGroup {
             if hasCompletedOnboarding {
                 ContentView()
             } else {
                 OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
             }
         }
     }
 }
 ```

 CUSTOMIZATION:
 ==============
 Easy to modify:
 - Change pages array
 - Add more pages
 - Different colors
 - Different icons
 - Different features
 - Add videos/animations

 ```swift
 private var pages: [OnboardingPage] {
     [
         OnboardingPage(
             title: "Your Title",
             subtitle: "Your Subtitle",
             description: "Your description...",
             imageName: "star.fill", // Any SF Symbol
             color: .orange, // Any Color
             features: [
                 "✨ Feature 1",
                 "🚀 Feature 2",
                 "💎 Feature 3"
             ]
         )
         // Add more pages...
     ]
 }
 ```

 ACCESSIBILITY:
 ==============
 SwiftUI has built-in accessibility:
 - VoiceOver support
 - Dynamic Type (text scaling)
 - High contrast mode
 - Reduce motion

 Enhance with:
 ```swift
 Text("Title")
     .accessibilityLabel("Welcome screen title")
     .accessibilityHint("First page of onboarding")
 ```

 TESTING:
 ========
 ```swift
 // Test with Xcode Previews
 #Preview("First Page") {
     OnboardingView(hasCompletedOnboarding: .constant(false))
 }

 #Preview("Last Page") {
     OnboardingView(hasCompletedOnboarding: .constant(false))
         .onAppear {
             // Simulate being on last page
         }
 }

 #Preview("Dark Mode") {
     OnboardingView(hasCompletedOnboarding: .constant(false))
         .preferredColorScheme(.dark)
 }
 ```

 NEXT STEPS:
 ===========
 - Add lottie animations
 - Add video backgrounds
 - Request permissions inline
 - A/B test different flows
 - Track completion rates
 */
