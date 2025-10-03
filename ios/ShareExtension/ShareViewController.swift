import UIKit
import SwiftUI
import UniformTypeIdentifiers

/**
 ShareViewController - Share Extension Entry Point

 LEARNING: iOS Share Extensions
 ================================
 Share Extensions let users share content from other apps to your app

 How it works:
 1. User takes screenshot in any app
 2. Taps Share button
 3. Selects "ReplyCopilot" from share sheet
 4. Extension processes the image
 5. Calls API to generate replies
 6. Shows suggestions
 7. User copies and pastes

 Technical details:
 - Separate target with its own bundle ID
 - Limited memory (~30MB)
 - Can't run indefinitely (watchdog timer)
 - Shares data via App Groups
 - Limited UI (modal sheet)

 LEARNING: UIKit in Extensions
 ===============================
 Share extensions use UIKit, not SwiftUI directly
 But we can embed SwiftUI views using UIHostingController
 */

class ShareViewController: UIViewController {

    // MARK: - Properties

    /// SwiftUI view for the extension UI
    private var hostingController: UIHostingController<ShareExtensionView>?

    /// API client
    private let apiClient = APIClient.shared

    /// Storage service
    private let storage = StorageService.shared

    /// Analytics service
    private let analytics = AnalyticsService.shared

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Track extension launch
        analytics.trackShareExtensionUsed(platform: nil)

        // Set up UI
        setupUI()

        // Process shared content
        processSharedContent()
    }

    // MARK: - UI Setup

    /**
     LEARNING: Embedding SwiftUI in UIKit
     =====================================
     UIHostingController bridges SwiftUI and UIKit
     - Create SwiftUI view
     - Wrap in UIHostingController
     - Add as child view controller
     - Constrain to parent view
     */

    private func setupUI() {
        // Create SwiftUI view with callbacks
        let swiftUIView = ShareExtensionView(
            onCancel: { [weak self] in
                self?.cancel()
            },
            onComplete: { [weak self] in
                self?.complete()
            }
        )

        // Create hosting controller
        let hostingController = UIHostingController(rootView: swiftUIView)
        self.hostingController = hostingController

        // Add as child
        addChild(hostingController)
        view.addSubview(hostingController.view)

        // Set up constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        hostingController.didMove(toParent: self)
    }

    // MARK: - Content Processing

    /**
     LEARNING: NSExtensionContext
     =============================
     Extension receives shared items via extensionContext
     - inputItems: Array of NSExtensionItem
     - attachments: Array of NSItemProvider
     - Can contain images, URLs, text, etc.
     */

    private func processSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            showError("No content to process")
            return
        }

        // Look for image attachment
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                loadImage(from: provider)
                return
            }
        }

        showError("No image found. Please share a screenshot.")
    }

    /**
     LEARNING: NSItemProvider
     ========================
     Asynchronous content loading
     - loadItem(forTypeIdentifier:)
     - Completion handler with result
     - Can provide multiple representations
     */

    private func loadImage(from provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] (item, error) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.showError("Failed to load image: \(error.localizedDescription)")
                    return
                }

                // Extract UIImage from item
                var image: UIImage?

                if let url = item as? URL {
                    image = UIImage(contentsOfFile: url.path)
                } else if let data = item as? Data {
                    image = UIImage(data: data)
                } else if let img = item as? UIImage {
                    image = img
                }

                guard let screenshot = image else {
                    self.showError("Failed to process image")
                    return
                }

                // Generate replies
                self.generateReplies(from: screenshot)
            }
        }
    }

    // MARK: - Reply Generation

    private func generateReplies(from image: UIImage) {
        // Update UI to show loading
        hostingController?.rootView.viewModel.isLoading = true

        // Load user preferences
        let preferences = storage.loadPreferences()
        let defaultTone = preferences?.defaultTone ?? .friendly

        // Detect platform (simplified - in real app, use ML)
        let platform = detectPlatform(from: image)

        // Get tone for platform
        let tone = preferences?.getTone(for: platform) ?? defaultTone

        // Get user ID if available
        let userId = try? storage.loadUserId()

        // Call API
        Task {
            do {
                let response = try await apiClient.generateReplies(
                    image: image,
                    platform: platform,
                    tone: tone,
                    userId: userId
                )

                await MainActor.run {
                    // Update UI with suggestions
                    hostingController?.rootView.viewModel.suggestions = response.suggestions
                    hostingController?.rootView.viewModel.isLoading = false

                    // Save to history
                    for suggestion in response.suggestions {
                        try? storage.addToHistory(suggestion)
                    }

                    // Share with keyboard extension
                    try? storage.saveSuggestionsForExtensions(response.suggestions)

                    // Track success
                    analytics.trackReplyGeneration(
                        platform: platform,
                        tone: tone,
                        success: true,
                        responseTime: response.processingTime
                    )
                }

            } catch let error as APIError {
                await MainActor.run {
                    hostingController?.rootView.viewModel.isLoading = false
                    hostingController?.rootView.viewModel.errorMessage = error.localizedDescription

                    analytics.trackAPIError(error)
                }
            } catch {
                await MainActor.run {
                    hostingController?.rootView.viewModel.isLoading = false
                    hostingController?.rootView.viewModel.errorMessage = "An unexpected error occurred"
                }
            }
        }
    }

    /**
     LEARNING: Platform Detection
     ============================
     In a production app, use:
     - ML model trained on screenshots
     - Color analysis (app themes)
     - Text recognition (OCR)
     - UI pattern matching

     For now, we'll default to WhatsApp
     */

    private func detectPlatform(from image: UIImage) -> Platform {
        // TODO: Implement ML-based platform detection
        // For now, return most common platform
        return .whatsapp
    }

    // MARK: - Completion

    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(
            domain: "com.replycopilot.share",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "User cancelled"]
        ))
    }

    private func complete() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func showError(_ message: String) {
        hostingController?.rootView.viewModel.errorMessage = message
    }
}

// MARK: - SwiftUI View

/**
 ShareExtensionView - SwiftUI UI for Share Extension

 LEARNING: SwiftUI in Extensions
 ================================
 Same SwiftUI code works in extensions!
 - State management
 - Animations
 - Modifiers
 - All the same patterns
 */

struct ShareExtensionView: View {

    @StateObject var viewModel = ShareExtensionViewModel()

    let onCancel: () -> Void
    let onComplete: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.suggestions.isEmpty {
                    emptyView
                } else {
                    suggestionsView
                }
            }
            .navigationTitle("Reply Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onComplete()
                    }
                    .disabled(viewModel.suggestions.isEmpty)
                }
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Analyzing screenshot...")
                .font(.headline)

            Text("Generating perfect replies")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Oops!")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                // Retry logic would go here
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Processing...")
                .font(.headline)
        }
    }

    private var suggestionsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Success message
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Generated \(viewModel.suggestions.count) suggestions")
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Suggestions
                ForEach(viewModel.suggestions) { suggestion in
                    SuggestionCardExtension(suggestion: suggestion) {
                        viewModel.copySuggestion(suggestion)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Suggestion Card for Extension

struct SuggestionCardExtension: View {
    let suggestion: ReplySuggestion
    let onCopy: () -> Void

    @State private var showingCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Badges
            HStack {
                Text("\(suggestion.tone.emoji) \(suggestion.tone.displayName)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.15))
                    .clipShape(Capsule())

                if let confidence = suggestion.confidence {
                    Text("\(suggestion.confidenceEmoji) \(Int(confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Reply text
            Text(suggestion.text)
                .font(.body)
                .textSelection(.enabled)

            // Copy button
            Button {
                UIPasteboard.general.string = suggestion.text
                onCopy()

                // Show feedback
                showingCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingCopied = false
                }
            } label: {
                HStack {
                    Image(systemName: showingCopied ? "checkmark" : "doc.on.doc")
                    Text(showingCopied ? "Copied!" : "Copy")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(showingCopied ? Color.green : Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(showingCopied)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - ViewModel

class ShareExtensionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var suggestions: [ReplySuggestion] = []
    @Published var errorMessage: String?

    private let analytics = AnalyticsService.shared

    func copySuggestion(_ suggestion: ReplySuggestion) {
        analytics.trackReplyCopied(tone: suggestion.tone, platform: suggestion.platform)
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. iOS Share Extensions
    - Separate app target
    - Own bundle ID
    - Limited resources
    - Modal UI
    - Process shared content

 2. NSExtensionContext
    - Receives shared items
    - inputItems array
    - Complete/cancel request
    - Return items

 3. NSItemProvider
    - Async content loading
    - Type identifiers
    - Multiple representations
    - Error handling

 4. UIHostingController
    - Bridge UIKit ↔ SwiftUI
    - Embed SwiftUI in UIKit
    - Child view controller
    - Constraint layout

 5. UTType (Uniform Type Identifiers)
    - Image types
    - Document types
    - Custom types
    - Type conformance

 6. App Groups
    - Share data between targets
    - Shared UserDefaults
    - Shared file container
    - Keychain sharing

 7. Memory Constraints
    - Limited to ~30MB
    - Compress images
    - Release resources
    - Avoid leaks

 8. Extension Lifecycle
    - Launched on demand
    - Watchdog timer
    - Can be terminated
    - Save state early

 XCODE CONFIGURATION:
 ====================

 1. Create Share Extension Target:
    - File → New → Target
    - Select "Share Extension"
    - Name: "ShareExtension"
    - Bundle ID: com.replycopilot.share

 2. Configure Info.plist:
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>NSExtensionActivationRule</key>
            <dict>
                <key>NSExtensionActivationSupportsImageWithMaxCount</key>
                <integer>1</integer>
            </dict>
        </dict>
        <key>NSExtensionMainStoryboard</key>
        <string>MainInterface</string>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.share-services</string>
    </dict>

 3. Add Capabilities:
    - App Groups: group.com.replycopilot.shared
    - Keychain Sharing

 4. Share Code:
    - Add files to both targets
    - Or create shared framework
    - Models, Services, etc.

 5. Link Frameworks:
    - Same as main app
    - Firebase (careful with size)
    - Custom frameworks

 USAGE FLOW:
 ===========

 1. User takes screenshot in WhatsApp
 2. Taps Share button
 3. Selects "ReplyCopilot" from share sheet
 4. Extension launches
 5. Loads image from share sheet
 6. Calls Azure OpenAI API
 7. Displays 3-5 suggestions
 8. User taps Copy on preferred reply
 9. Returns to WhatsApp
 10. Pastes reply
 11. Extension closes

 TESTING:
 ========

 1. Run extension target from Xcode
 2. Select "Photos" or "Safari" as host app
 3. In host app, share an image
 4. Select your extension
 5. Debug in Xcode

 OR

 1. Build and run main app
 2. Take screenshot (Cmd+Shift+4 in simulator)
 3. Tap screenshot preview
 4. Tap Share button
 5. Select ReplyCopilot

 OPTIMIZATION:
 =============

 Memory:
 - Compress images before upload
 - Release references early
 - Avoid caching
 - Monitor memory warnings

 Speed:
 - Minimize initialization
 - Cache API client
 - Preload preferences
 - Show UI immediately

 TROUBLESHOOTING:
 ================

 Extension not appearing:
 - Check Info.plist activation rules
 - Verify bundle ID
 - Rebuild and reinstall
 - Restart device

 Extension crashes:
 - Check memory usage
 - Verify App Groups config
 - Check API timeouts
 - View device logs

 Can't share data:
 - Verify App Groups enabled
 - Check group identifier matches
 - Test keychain access
 - Check file permissions

 NEXT STEPS:
 ===========
 - Add platform detection ML model
 - Add image cropping UI
 - Add tone picker
 - Add favorites/recent tones
 - Add offline caching
 - Add usage analytics
 */
