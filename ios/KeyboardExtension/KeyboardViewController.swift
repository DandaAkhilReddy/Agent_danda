import UIKit
import SwiftUI

/**
 KeyboardViewController - Custom Keyboard Extension

 LEARNING: iOS Custom Keyboards
 ================================
 Custom keyboards replace the system keyboard
 Allow users to type with your UI

 Key concepts:
 - UIInputViewController base class
 - Limited UI space
 - Memory constraints (~30MB)
 - Security restrictions
 - Open Access permission required
 - Can't access network without permission

 Use cases:
 - Custom layouts (emoji, GIFs)
 - Text expansion
 - Translation
 - Quick replies (our use case!)

 LEARNING: Keyboard Architecture
 ================================
 1. User enables keyboard in Settings
 2. User switches to your keyboard
 3. Extension loads
 4. Shows custom UI
 5. User taps suggestion
 6. Insert text into document
 7. User switches back to system keyboard

 IMPORTANT: Privacy & Security
 ==============================
 - Can't access network by default
 - Need "Allow Full Access" for:
   - Network requests
   - Shared containers
   - Keychain
 - Users are wary of keyboard permissions
 - Must handle both modes gracefully
 */

class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    /// SwiftUI hosting controller
    private var hostingController: UIHostingController<KeyboardView>?

    /// Storage service
    private let storage = StorageService.shared

    /// Analytics service
    private let analytics = AnalyticsService.shared

    /// Has full access permission
    private var hasFullAccess: Bool {
        UIPasteboard.general.hasStrings // Proxy for full access
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Track keyboard launch
        analytics.trackKeyboardExtensionUsed()

        // Set up UI
        setupKeyboardUI()

        // Load suggestions
        loadSuggestions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Refresh suggestions
        loadSuggestions()
    }

    // MARK: - UI Setup

    /**
     LEARNING: Keyboard Height
     =========================
     Custom keyboards should respect:
     - Compact height: ~280 points
     - iPhone portrait: 216-280 points
     - iPhone landscape: 162-216 points
     - iPad: More flexible
     */

    private func setupKeyboardUI() {
        // Create SwiftUI view
        let keyboardView = KeyboardView(
            hasFullAccess: hasFullAccess,
            onInsertText: { [weak self] text in
                self?.insertText(text)
            },
            onRequestFullAccess: { [weak self] in
                self?.showFullAccessInstructions()
            },
            onSwitchKeyboard: { [weak self] in
                self?.advanceToNextInputMode()
            }
        )

        // Create hosting controller
        let hostingController = UIHostingController(rootView: keyboardView)
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
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 280)
        ])

        hostingController.didMove(toParent: self)

        // Set keyboard background
        view.backgroundColor = UIColor.systemBackground
    }

    // MARK: - Data Loading

    /**
     LEARNING: App Groups in Keyboard
     =================================
     Keyboard extensions are sandboxed
     Can't access main app's data normally
     Must use App Groups to share data
     */

    private func loadSuggestions() {
        guard hasFullAccess else {
            // Can't access shared data without full access
            return
        }

        // Load suggestions from App Group
        let suggestions = storage.loadSuggestionsFromExtensions()

        // Update UI
        hostingController?.rootView.viewModel.suggestions = suggestions
    }

    // MARK: - Text Insertion

    /**
     LEARNING: Text Input Protocol
     ==============================
     textDocumentProxy: Interface to the text field
     - insertText(_:) - Insert string
     - deleteBackward() - Delete character
     - documentContextBeforeInput - Text before cursor
     - documentContextAfterInput - Text after cursor
     */

    private func insertText(_ text: String) {
        textDocumentProxy.insertText(text)

        // Track usage
        analytics.trackButtonTap("insert_text_keyboard")

        // Optionally dismiss keyboard
        // advanceToNextInputMode()
    }

    // MARK: - Permissions

    private func showFullAccessInstructions() {
        // Can't show alerts from keyboard
        // Must show in-keyboard UI
        hostingController?.rootView.viewModel.showingFullAccessInfo = true
    }

    override func textWillChange(_ textInput: UITextInput?) {
        // Called when text is about to change
    }

    override func textDidChange(_ textInput: UITextInput?) {
        // Called when text changed
        // Could use this to provide contextual suggestions
    }
}

// MARK: - SwiftUI Keyboard View

/**
 KeyboardView - SwiftUI UI for Keyboard Extension
 */

struct KeyboardView: View {

    @StateObject var viewModel = KeyboardViewModel()

    let hasFullAccess: Bool
    let onInsertText: (String) -> Void
    let onRequestFullAccess: () -> Void
    let onSwitchKeyboard: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar
            keyboardToolbar

            Divider()

            if hasFullAccess {
                if viewModel.showingFullAccessInfo {
                    fullAccessInfoView
                } else if viewModel.suggestions.isEmpty {
                    emptySuggestionsView
                } else {
                    suggestionsView
                }
            } else {
                noFullAccessView
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Subviews

    /**
     LEARNING: Keyboard UI Design
     =============================
     Best practices:
     - Keep it compact (limited height)
     - Large tap targets (44pt minimum)
     - Clear visual hierarchy
     - Fast response to taps
     - Match system keyboard style
     */

    private var keyboardToolbar: some View {
        HStack {
            Button {
                onSwitchKeyboard()
            } label: {
                Image(systemName: "globe")
                    .font(.title3)
            }

            Spacer()

            Text("ReplyCopilot")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Spacer()

            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    private var suggestionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.suggestions) { suggestion in
                    SuggestionButton(suggestion: suggestion) {
                        onInsertText(suggestion.text)
                    }
                }
            }
            .padding()
        }
    }

    private var emptySuggestionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "message.badge")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("No suggestions yet")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Generate replies using the Share Extension")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private var noFullAccessView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Full Access Required")
                .font(.headline)

            Text("Enable Full Access in Settings to use quick replies")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                onRequestFullAccess()
            } label: {
                Text("How to Enable")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }

            Button {
                onSwitchKeyboard()
            } label: {
                Text("Use System Keyboard")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }

    private var fullAccessInfoView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Enable Full Access")
                        .font(.headline)
                    Spacer()
                    Button("Close") {
                        viewModel.showingFullAccessInfo = false
                    }
                }

                Text("Follow these steps:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    InstructionStep(number: 1, text: "Open Settings app")
                    InstructionStep(number: 2, text: "Tap General → Keyboard → Keyboards")
                    InstructionStep(number: 3, text: "Tap ReplyCopilot")
                    InstructionStep(number: 4, text: "Enable 'Allow Full Access'")
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                        Text("Your Privacy is Protected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Text("We never collect or store anything you type. Full Access is only used to load your reply suggestions from the app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .frame(height: 250)
    }
}

// MARK: - Suggestion Button

struct SuggestionButton: View {
    let suggestion: ReplySuggestion
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Tone badge
                HStack {
                    Text(suggestion.tone.emoji)
                        .font(.caption)

                    if let confidence = suggestion.confidence {
                        Text("\(Int(confidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                // Reply text
                Text(suggestion.text)
                    .font(.subheadline)
                    .lineLimit(3)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                // Character count
                Text("\(suggestion.characterCount) chars")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 200, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Instruction Step

struct InstructionStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - ViewModel

class KeyboardViewModel: ObservableObject {
    @Published var suggestions: [ReplySuggestion] = []
    @Published var showingFullAccessInfo = false

    private let storage = StorageService.shared

    func refresh() {
        suggestions = storage.loadSuggestionsFromExtensions()
    }
}

/**
 KEY CONCEPTS LEARNED:
 =====================

 1. Custom Keyboards
    - UIInputViewController
    - Replace system keyboard
    - Limited height
    - Memory constraints

 2. Text Input Protocol
    - textDocumentProxy
    - insertText()
    - deleteBackward()
    - Document context

 3. Full Access Permission
    - Required for:
      - Network access
      - Shared containers
      - Keychain
    - Users must enable manually
    - Check hasFullAccess

 4. App Groups
    - Share data with keyboard
    - SharedDefaults
    - File containers
    - Essential for keyboard

 5. Keyboard UI
    - Compact design
    - Large tap targets
    - Fast response
    - Match system style

 6. Security & Privacy
    - Can't access network by default
    - Limited access to APIs
    - User privacy concerns
    - Clear communication

 7. Keyboard Lifecycle
    - Loaded on demand
    - Can be terminated
    - Minimal memory
    - Fast launch

 8. Switching Keyboards
    - advanceToNextInputMode()
    - Globe button
    - Long press for menu

 XCODE CONFIGURATION:
 ====================

 1. Create Keyboard Extension Target:
    - File → New → Target
    - Select "Custom Keyboard"
    - Name: "KeyboardExtension"
    - Bundle ID: com.replycopilot.keyboard

 2. Configure Info.plist:
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>IsASCIICapable</key>
            <false/>
            <key>PrefersRightToLeft</key>
            <false/>
            <key>PrimaryLanguage</key>
            <string>en-US</string>
            <key>RequestsOpenAccess</key>
            <false/>
        </dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.keyboard-service</string>
        <key>NSExtensionPrincipalClass</key>
        <string>$(PRODUCT_MODULE_NAME).KeyboardViewController</string>
    </dict>

 3. Add Capabilities:
    - App Groups: group.com.replycopilot.shared

 4. Request Full Access (optional):
    - Set RequestsOpenAccess to true
    - Show clear explanation to users
    - Handle both modes gracefully

 INSTALLATION:
 =============

 1. User installs app
 2. User opens Settings app
 3. General → Keyboard → Keyboards
 4. Add New Keyboard...
 5. Select ReplyCopilot
 6. Optionally enable Full Access

 USAGE FLOW:
 ===========

 1. User is in messaging app
 2. Tap text field (keyboard appears)
 3. Tap globe icon to switch keyboards
 4. Select ReplyCopilot
 5. Keyboard shows recent suggestions
 6. User taps a suggestion
 7. Text is inserted
 8. User can switch back or send

 TESTING:
 ========

 1. Run keyboard target from Xcode
 2. Select host app (Messages, Notes)
 3. Tap text field
 4. Switch to your keyboard
 5. Debug in Xcode

 OR

 1. Install on device
 2. Enable keyboard in Settings
 3. Test in any app
 4. Check Console.app for logs

 OPTIMIZATION:
 =============

 Memory:
 - Minimize cached data
 - Release unused resources
 - Avoid heavy frameworks
 - Monitor memory warnings

 Performance:
 - Fast launch time
 - Responsive UI
 - Minimal initialization
 - Efficient rendering

 Size:
 - Keep extension small
 - Avoid large frameworks
 - Share code with main app
 - Use system resources

 TROUBLESHOOTING:
 ================

 Keyboard not appearing:
 - Check enabled in Settings
 - Verify bundle ID
 - Rebuild and reinstall
 - Restart device

 Can't access data:
 - Enable Full Access
 - Check App Groups config
 - Verify group identifier
 - Check entitlements

 Keyboard crashes:
 - Check memory usage
 - Verify nil checks
 - Review logs
 - Test on device

 PRIVACY CONSIDERATIONS:
 =======================

 What to communicate to users:
 ✅ We only load your suggestions
 ✅ We never log keystrokes
 ✅ We never transmit typed text
 ✅ Full Access only for app data

 What NOT to do:
 ❌ Log user typing
 ❌ Track keystrokes
 ❌ Send data to server
 ❌ Access clipboard unnecessarily

 NEXT STEPS:
 ===========
 - Add favorites/pinned replies
 - Add categories/folders
 - Add search functionality
 - Add haptic feedback
 - Add sound effects
 - Add themes
 - Add custom layouts
 */
